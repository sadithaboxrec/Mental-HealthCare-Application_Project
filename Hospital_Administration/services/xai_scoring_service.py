import json
import re
from pathlib import Path


ENGINE_VERSION = "flask-xai-1.0.0"
SCREENING_NOTE = (
    "XAI analysis is supportive evidence only and does not replace "
    "validated screening such as PHQ-9, PHQ-A, GAD-7, ASQ, or C-SSRS workflows."
)


class XaiLexiconScorer:
    def __init__(self, lexicon_path=None):
        base_dir = Path(__file__).resolve().parents[1]
        self.lexicon_path = Path(lexicon_path) if lexicon_path else base_dir / "data" / "xai_lexicons.json"
        with self.lexicon_path.open("r", encoding="utf-8-sig") as f:
            self.lexicon = json.load(f)

        self.lexicon_version = self.lexicon.get("schemaVersion", "unknown")
        self.scoring = self.lexicon.get("scoring", {})
        self.privacy = self.scoring.get("privacy", {})
        self.categories = self.lexicon.get("categories", [])
        self.category_by_key = {category["key"]: category for category in self.categories}
        self.critical_overrides = set(self.scoring.get("criticalOverrideCategories", []))
        self.warning_overrides = set(self.scoring.get("warningOverrideCategories", []))
        self.severity_bands = self.lexicon.get("severityBands", [])
        # Wire nonLexiconSignals so service files read weights from the JSON, not hardcode
        self.non_lexicon_signals = {
            sig["key"]: sig
            for sig in self.lexicon.get("nonLexiconSignals", [])
        }

    def get_behavioral_weight(self, key, default=2):
        """Return the configured weight for a behavioral (non-lexicon) signal key.
        Falls back to `default` if the key is not in the nonLexiconSignals catalog."""
        sig = self.non_lexicon_signals.get(key)
        if sig is None:
            return default
        return int(sig.get("weight", default))

    def analyze_text(self, text, source="text", source_id="", timestamp=""):
        raw_text = text or ""
        normalized = self._normalize(raw_text)
        matched = []
        raw_score = 0
        has_critical_override = False
        has_warning_override = False

        for category in self.categories:
            terms = category.get("terms", [])
            term_counts = {}
            match_count = 0
            for term in terms:
                count = self._count_occurrences(normalized, self._normalize(term))
                if count:
                    term_counts[term] = count
                    match_count += count

            if not match_count:
                continue

            key = category["key"]
            weight = int(category.get("weight", 0))
            contribution = match_count * weight
            raw_score += contribution
            has_critical_override = has_critical_override or key in self.critical_overrides
            has_warning_override = has_warning_override or key in self.warning_overrides
            matched.append({
                "key": key,
                "displayName": category.get("displayName", key),
                "weight": weight,
                "matchCount": match_count,
                "scoreContribution": contribution,
                "explicit": bool(category.get("explicit", False)),
                "whyItMatters": category.get("whyItMatters", "Relevant XAI signal detected."),
                "privacySnippetTemplate": category.get(
                    "privacySnippetTemplate",
                    "A privacy-gated clinical signal was detected.",
                ),
                "matchedTerms": sorted(term_counts.keys()),
            })

        score = max(0, raw_score)
        severity, band = self._severity_for_score(score)
        if has_warning_override and self._severity_rank(severity) < 2:
            severity = "warning"
            band = 2
        if has_critical_override:
            severity = "critical"
            band = 3

        evidence = [
            self._evidence_item(item, source, source_id, timestamp)
            for item in matched
        ]

        primary_drivers = [
            self._primary_driver(item, source, timestamp)
            for item in sorted(
                matched,
                key=lambda item: (item["scoreContribution"], item["weight"], item["matchCount"]),
                reverse=True,
            )
            if item["scoreContribution"] > 0
        ]

        return {
            "source": source,
            "sourceId": source_id,
            "timestamp": timestamp,
            "score": score,
            "rawScore": raw_score,
            "severity": severity,
            "band": band,
            "themes": [item["key"] for item in matched],
            "themeCounts": {item["key"]: item["matchCount"] for item in matched},
            "evidence": evidence,
            "primaryDrivers": primary_drivers,
            "matchedCategories": matched,
            "explicit": has_warning_override or has_critical_override,
            "explicitSelfHarm": has_warning_override,
            "explicitPlanOrPreparation": has_critical_override,
        }

    def signal_item(
        self,
        key,
        display_name,
        weight,
        source,
        timestamp="",
        source_id="",
        why_it_matters="Relevant behavioral signal detected.",
        snippet="A privacy-gated behavioral signal was detected.",
        explicit=False,
    ):
        score = max(0, int(weight))
        severity, band = self._severity_for_score(score)
        evidence = {
            "source": source,
            "sourceId": source_id,
            "timestamp": timestamp,
            "theme": key,
            "displayName": display_name,
            "matchCount": 1,
            "weight": int(weight),
            "explicit": explicit,
            "whyItMatters": why_it_matters,
            "excerpt": snippet,
        }
        return {
            "source": source,
            "sourceId": source_id,
            "timestamp": timestamp,
            "score": score,
            "rawScore": int(weight),
            "severity": severity,
            "band": band,
            "themes": [key],
            "themeCounts": {key: 1},
            "evidence": [evidence],
            "primaryDrivers": [{
                "vector": source,
                "theme": key,
                "displayName": display_name,
                "weight": int(weight),
                "matchCount": 1,
                "scoreContribution": int(weight),
                "evidenceSnippet": snippet,
                "timestamp": timestamp,
            }],
            "matchedCategories": [],
            "explicit": explicit,
            "explicitSelfHarm": False,
            "explicitPlanOrPreparation": False,
        }

    def _severity_for_score(self, score):
        for band in self.severity_bands:
            min_score = band.get("minScore", 0)
            max_score = band.get("maxScore")
            if score >= min_score and (max_score is None or score <= max_score):
                return band.get("key", "stable"), band.get("band", 0)
        if score >= int(self.scoring.get("criticalScoreThreshold", 8)):
            return "critical", 3
        if score >= int(self.scoring.get("warningScoreThreshold", 5)):
            return "warning", 2
        if score >= int(self.scoring.get("watchScoreThreshold", 2)):
            return "watch", 1
        return "stable", 0

    @staticmethod
    def _severity_rank(severity):
        return {"stable": 0, "watch": 1, "warning": 2, "critical": 3}.get(severity, 0)

    @staticmethod
    def _normalize(text):
        return re.sub(r"\s+", " ", str(text).lower()).strip()

    @staticmethod
    def _count_occurrences(text, phrase):
        if not phrase:
            return 0
        return text.count(phrase)

    @staticmethod
    def _evidence_item(item, source, source_id, timestamp):
        snippet = (
            f"{item['privacySnippetTemplate']} "
            f"Detected {item['matchCount']} marker(s) for {item['displayName']}."
        )
        return {
            "source": source,
            "sourceId": source_id,
            "entryId": source_id,
            "timestamp": timestamp,
            "theme": item["key"],
            "displayName": item["displayName"],
            "matchCount": item["matchCount"],
            "weight": item["weight"],
            "explicit": item["explicit"],
            "whyItMatters": item["whyItMatters"],
            "excerpt": snippet,
        }

    @staticmethod
    def _primary_driver(item, source, timestamp):
        snippet = (
            f"{item['privacySnippetTemplate']} "
            f"Detected {item['matchCount']} marker(s)."
        )
        return {
            "vector": source,
            "theme": item["key"],
            "displayName": item["displayName"],
            "weight": item["weight"],
            "matchCount": item["matchCount"],
            "scoreContribution": item["scoreContribution"],
            "evidenceSnippet": snippet,
            "timestamp": timestamp,
        }


_DEFAULT_SCORER = None


def get_default_scorer():
    global _DEFAULT_SCORER
    if _DEFAULT_SCORER is None:
        _DEFAULT_SCORER = XaiLexiconScorer()
    return _DEFAULT_SCORER
