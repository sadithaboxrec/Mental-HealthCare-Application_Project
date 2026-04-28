import json
from pathlib import Path

DATA_DIR = Path(__file__).resolve().parents[3] / "data"


def _load(relative_path):
    return json.loads((DATA_DIR / relative_path).read_text(encoding="utf-8-sig"))


def test_shared_departments_have_unique_ids_and_required_fields():
    departments = _load("shared/departments.json")

    ids = [item["id"] for item in departments]

    assert len(departments) >= 10
    assert len(ids) == len(set(ids))
    assert all(item["name"].strip() for item in departments)
    assert all(item["type"] in {"Medical", "Therapy", "Counseling"} for item in departments)
    assert all(item["description"].strip() for item in departments)


def test_shared_specializations_have_unique_ids_and_valid_categories():
    specializations = _load("shared/specializations.json")

    ids = [item["id"] for item in specializations]

    assert len(specializations) >= 20
    assert len(ids) == len(set(ids))
    assert all(item["category"] in {"Medical", "Therapy", "Counseling"} for item in specializations)
    assert all(item["name"].strip() for item in specializations)


def test_medication_catalog_contains_structured_non_empty_entries():
    catalog = _load("doctor/medication_catalog.json")
    medications = catalog["medications"]

    ids = [item["id"] for item in medications]

    assert catalog["schemaVersion"]
    assert len(medications) >= 50
    assert len(ids) == len(set(ids))
    for medication in medications:
        assert medication["genericName"].strip()
        assert medication["displayName"].strip()
        assert isinstance(medication["commonForms"], list)
        assert isinstance(medication["monitoringTags"], list)
        assert isinstance(medication["isControlledMedication"], bool)
        assert isinstance(medication["requiresExtraCaution"], bool)


def test_xai_lexicon_contract_has_severity_bands_categories_and_output_fields():
    lexicon = _load("analysis/xai_lexicons.json")

    severity_keys = {band["key"] for band in lexicon["severityBands"]}
    category_keys = [category["key"] for category in lexicon["categories"]]
    required_fields = set(lexicon["outcomePayloadContract"]["requiredFields"])

    assert severity_keys == {"stable", "watch", "warning", "critical"}
    assert len(category_keys) == len(set(category_keys))
    assert {"self_harm", "plan_preparation", "protective_factor"} <= set(category_keys)
    assert {
        "patientUid",
        "severity",
        "score",
        "confidence",
        "evidence",
        "screeningNote",
    } <= required_fields
    assert all(category["terms"] for category in lexicon["categories"])
