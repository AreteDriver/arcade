from __future__ import annotations

import json
import tempfile
from pathlib import Path

from systems.dialogue_engine import DialogueTree

SAMPLE_DIALOGUE = {
    "start": "greeting",
    "nodes": {
        "greeting": {
            "text": "Welcome, capsuleer.",
            "choices": [
                {"text": "Looking for work.", "next": "work"},
                {"text": "I have intel.", "next": "intel", "condition": "has_secret_data"},
                {"text": "Check my flag.", "next": "flagged", "condition": "flag_trusted"},
                {"text": "High standing only.", "next": "vip", "condition": "faction_Caldari_5"},
                {"text": "Goodbye.", "next": None},
            ],
        },
        "work": {
            "text": "Deliver supplies to Nonni.",
            "choices": [
                {
                    "text": "Accept.",
                    "next": "accepted",
                    "effect": {
                        "faction": {"Caldari Navy": 5},
                        "add_item": "supply_contract",
                        "set_flag": {"mission_accepted": True},
                    },
                },
                {"text": "Decline.", "next": None},
            ],
        },
        "accepted": {
            "text": "Fly safe.",
            "choices": [
                {
                    "text": "Remove item test.",
                    "next": None,
                    "effect": {"remove_item": "supply_contract"},
                }
            ],
        },
        "intel": {
            "text": "Valuable intel.",
            "choices": [{"text": "Done.", "next": None}],
        },
        "flagged": {
            "text": "You are trusted.",
            "choices": [{"text": "Done.", "next": None}],
        },
        "vip": {
            "text": "Welcome, honored ally.",
            "choices": [{"text": "Done.", "next": None}],
        },
    },
}


def _write_dialogue(data: dict) -> Path:
    f = tempfile.NamedTemporaryFile(mode="w", suffix=".json", delete=False)
    json.dump(data, f)
    f.close()
    return Path(f.name)


class TestDialogueTree:
    def test_load_and_current_node(self) -> None:
        path = _write_dialogue(SAMPLE_DIALOGUE)
        try:
            gs = {"inventory": [], "flags": {}, "factions": {}}
            dt = DialogueTree(path, gs)
            node = dt.current_node()
            assert node is not None
            assert node["text"] == "Welcome, capsuleer."
        finally:
            path.unlink()

    def test_choices_filters_conditions(self) -> None:
        path = _write_dialogue(SAMPLE_DIALOGUE)
        try:
            gs = {"inventory": [], "flags": {}, "factions": {}}
            dt = DialogueTree(path, gs)
            choices = dt.choices()
            texts = [c["text"] for c in choices]
            assert "Looking for work." in texts
            assert "Goodbye." in texts
            # Conditional ones should be filtered out
            assert "I have intel." not in texts
            assert "Check my flag." not in texts
            assert "High standing only." not in texts
        finally:
            path.unlink()

    def test_has_condition(self) -> None:
        path = _write_dialogue(SAMPLE_DIALOGUE)
        try:
            gs = {"inventory": ["secret_data"], "flags": {}, "factions": {}}
            dt = DialogueTree(path, gs)
            choices = dt.choices()
            texts = [c["text"] for c in choices]
            assert "I have intel." in texts
        finally:
            path.unlink()

    def test_flag_condition(self) -> None:
        path = _write_dialogue(SAMPLE_DIALOGUE)
        try:
            gs = {"inventory": [], "flags": {"trusted": True}, "factions": {}}
            dt = DialogueTree(path, gs)
            choices = dt.choices()
            texts = [c["text"] for c in choices]
            assert "Check my flag." in texts
        finally:
            path.unlink()

    def test_faction_condition(self) -> None:
        path = _write_dialogue(SAMPLE_DIALOGUE)
        try:
            gs = {"inventory": [], "flags": {}, "factions": {"Caldari": 5}}
            dt = DialogueTree(path, gs)
            choices = dt.choices()
            texts = [c["text"] for c in choices]
            assert "High standing only." in texts
        finally:
            path.unlink()

    def test_faction_condition_below_threshold(self) -> None:
        path = _write_dialogue(SAMPLE_DIALOGUE)
        try:
            gs = {"inventory": [], "flags": {}, "factions": {"Caldari": 3}}
            dt = DialogueTree(path, gs)
            choices = dt.choices()
            texts = [c["text"] for c in choices]
            assert "High standing only." not in texts
        finally:
            path.unlink()

    def test_advance_applies_faction_effect(self) -> None:
        path = _write_dialogue(SAMPLE_DIALOGUE)
        try:
            gs = {"inventory": [], "flags": {}, "factions": {}}
            dt = DialogueTree(path, gs)
            # Choose "Looking for work." (index 0 of filtered choices)
            dt.advance(0)
            assert dt.current_node()["text"] == "Deliver supplies to Nonni."
            # Choose "Accept." (index 0)
            dt.advance(0)
            assert gs["factions"]["Caldari Navy"] == 5
        finally:
            path.unlink()

    def test_advance_applies_add_item_effect(self) -> None:
        path = _write_dialogue(SAMPLE_DIALOGUE)
        try:
            gs = {"inventory": [], "flags": {}, "factions": {}}
            dt = DialogueTree(path, gs)
            dt.advance(0)  # -> work
            dt.advance(0)  # -> accepted, effect: add_item
            assert "supply_contract" in gs["inventory"]
        finally:
            path.unlink()

    def test_advance_applies_set_flag_effect(self) -> None:
        path = _write_dialogue(SAMPLE_DIALOGUE)
        try:
            gs = {"inventory": [], "flags": {}, "factions": {}}
            dt = DialogueTree(path, gs)
            dt.advance(0)  # -> work
            dt.advance(0)  # -> accepted, effect: set_flag
            assert gs["flags"]["mission_accepted"] is True
        finally:
            path.unlink()

    def test_advance_applies_remove_item_effect(self) -> None:
        path = _write_dialogue(SAMPLE_DIALOGUE)
        try:
            gs = {"inventory": [], "flags": {}, "factions": {}}
            dt = DialogueTree(path, gs)
            dt.advance(0)  # -> work
            dt.advance(0)  # -> accepted (add_item adds supply_contract)
            assert "supply_contract" in gs["inventory"]
            dt.advance(0)  # -> None, effect: remove_item
            assert "supply_contract" not in gs["inventory"]
        finally:
            path.unlink()

    def test_remove_item_not_in_inventory(self) -> None:
        path = _write_dialogue(SAMPLE_DIALOGUE)
        try:
            gs = {"inventory": [], "flags": {}, "factions": {}}
            dt = DialogueTree(path, gs)
            dt.advance(0)  # -> work
            dt.advance(0)  # -> accepted
            dt.advance(0)  # -> None, effect: remove_item (item not present)
            # should not raise
            assert "supply_contract" not in gs["inventory"]
        finally:
            path.unlink()

    def test_advance_invalid_index(self) -> None:
        path = _write_dialogue(SAMPLE_DIALOGUE)
        try:
            gs = {"inventory": [], "flags": {}, "factions": {}}
            dt = DialogueTree(path, gs)
            result = dt.advance(99)
            assert result is None
            assert dt.is_finished()
        finally:
            path.unlink()

    def test_advance_negative_index(self) -> None:
        path = _write_dialogue(SAMPLE_DIALOGUE)
        try:
            gs = {"inventory": [], "flags": {}, "factions": {}}
            dt = DialogueTree(path, gs)
            result = dt.advance(-1)
            assert result is None
            assert dt.is_finished()
        finally:
            path.unlink()

    def test_advance_to_null_next(self) -> None:
        path = _write_dialogue(SAMPLE_DIALOGUE)
        try:
            gs = {"inventory": [], "flags": {}, "factions": {}}
            dt = DialogueTree(path, gs)
            # "Goodbye" is at index 1 in filtered list (work, goodbye)
            dt.advance(1)
            assert dt.is_finished()
        finally:
            path.unlink()

    def test_is_finished(self) -> None:
        path = _write_dialogue(SAMPLE_DIALOGUE)
        try:
            gs = {"inventory": [], "flags": {}, "factions": {}}
            dt = DialogueTree(path, gs)
            assert not dt.is_finished()
            dt.advance(1)  # Goodbye -> null
            assert dt.is_finished()
        finally:
            path.unlink()

    def test_reset(self) -> None:
        path = _write_dialogue(SAMPLE_DIALOGUE)
        try:
            gs = {"inventory": [], "flags": {}, "factions": {}}
            dt = DialogueTree(path, gs)
            dt.advance(0)  # move to work
            assert dt.current_node()["text"] != "Welcome, capsuleer."
            dt.reset()
            assert dt.current_node()["text"] == "Welcome, capsuleer."
        finally:
            path.unlink()

    def test_choices_when_finished(self) -> None:
        path = _write_dialogue(SAMPLE_DIALOGUE)
        try:
            gs = {"inventory": [], "flags": {}, "factions": {}}
            dt = DialogueTree(path, gs)
            dt.advance(1)  # Goodbye
            assert dt.choices() == []
        finally:
            path.unlink()

    def test_invalid_json_raises(self) -> None:
        f = tempfile.NamedTemporaryFile(mode="w", suffix=".json", delete=False)
        f.write("not valid json")
        f.close()
        path = Path(f.name)
        try:
            import pytest
            with pytest.raises(json.JSONDecodeError):
                DialogueTree(path, {})
        finally:
            path.unlink()

    def test_missing_file_raises(self) -> None:
        import pytest
        with pytest.raises(FileNotFoundError):
            DialogueTree(Path("/tmp/nonexistent_dialogue_12345.json"), {})
