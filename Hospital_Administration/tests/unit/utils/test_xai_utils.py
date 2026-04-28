from datetime import datetime, timezone

from services import xai_utils


def test_parse_datetime_normalizes_naive_and_zulu_values():
    naive = xai_utils.parse_datetime("2026-04-27T10:15:00")
    zulu = xai_utils.parse_datetime("2026-04-27T10:15:00Z")

    assert naive == datetime(2026, 4, 27, 10, 15, tzinfo=timezone.utc)
    assert zulu == datetime(2026, 4, 27, 10, 15, tzinfo=timezone.utc)


def test_date_key_falls_back_to_date_prefix_for_invalid_values():
    assert xai_utils.date_key("2026-04-27 pending") == "2026-04-27"
    assert xai_utils.date_key("soon") == "soon"
    assert xai_utils.date_key(None) == ""


def test_severity_helpers_are_stable_at_band_edges():
    assert xai_utils.severity_for_score(0) == ("stable", 0)
    assert xai_utils.severity_for_score(2) == ("watch", 1)
    assert xai_utils.severity_for_score(5) == ("warning", 2)
    assert xai_utils.severity_for_score(8) == ("critical", 3)
    assert xai_utils.severity_rank("warning") > xai_utils.severity_rank("watch")


def test_safe_number_parsing_handles_free_text():
    assert xai_utils.safe_int("7") == 7
    assert xai_utils.safe_int("bad", default=4) == 4
    assert xai_utils.safe_float("slept 6.5 hours") == 6.5
    assert xai_utils.safe_float("") is None


def test_latest_activity_at_uses_supported_timestamp_fields():
    latest = xai_utils.latest_activity_at(
        [{"createdAt": "2026-04-25T08:00:00Z"}],
        [{"updatedAt": "2026-04-26T08:00:00Z"}],
        [{"date": "2026-04-24"}],
    )

    assert latest == datetime(2026, 4, 26, 8, tzinfo=timezone.utc)
