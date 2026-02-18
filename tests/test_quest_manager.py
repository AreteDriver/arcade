from __future__ import annotations

import json
import tempfile
from pathlib import Path

from systems.quest_manager import ChronicleProgress, QuestManager


class TestChronicleProgress:
    def test_defaults(self) -> None:
        cp = ChronicleProgress("q1", "stage_a")
        assert cp.chronicle_id == "q1"
        assert cp.current_stage == "stage_a"
        assert cp.completed is False
        assert cp.flags == {}


class TestQuestManager:
    def test_start_chronicle(self) -> None:
        qm = QuestManager()
        qm.start_chronicle("supply_run", "depart")
        progress = qm.get_progress("supply_run")
        assert progress is not None
        assert progress.current_stage == "depart"

    def test_get_progress_unknown(self) -> None:
        qm = QuestManager()
        assert qm.get_progress("nonexistent") is None

    def test_advance_stage(self) -> None:
        qm = QuestManager()
        qm.start_chronicle("supply_run", "depart")
        qm.advance_stage("supply_run", "deliver")
        assert qm.get_progress("supply_run").current_stage == "deliver"

    def test_advance_stage_unknown_chronicle(self) -> None:
        qm = QuestManager()
        qm.advance_stage("nope", "stage2")  # should not raise

    def test_set_flag(self) -> None:
        qm = QuestManager()
        qm.start_chronicle("supply_run", "depart")
        qm.set_flag("supply_run", "ambushed", True)
        assert qm.get_progress("supply_run").flags["ambushed"] is True

    def test_set_flag_unknown_chronicle(self) -> None:
        qm = QuestManager()
        qm.set_flag("nope", "flag", True)  # should not raise

    def test_complete_chronicle(self) -> None:
        qm = QuestManager()
        qm.start_chronicle("supply_run", "depart")
        qm.complete_chronicle("supply_run")
        assert qm.get_progress("supply_run").completed is True

    def test_complete_unknown_chronicle(self) -> None:
        qm = QuestManager()
        qm.complete_chronicle("nope")  # should not raise

    def test_full_lifecycle(self) -> None:
        qm = QuestManager()
        qm.start_chronicle("caldari_supply", "travel")
        qm.set_flag("caldari_supply", "met_contact", True)
        qm.advance_stage("caldari_supply", "deliver")
        qm.set_flag("caldari_supply", "cargo_intact", True)
        qm.complete_chronicle("caldari_supply")

        progress = qm.get_progress("caldari_supply")
        assert progress.completed is True
        assert progress.current_stage == "deliver"
        assert progress.flags == {"met_contact": True, "cargo_intact": True}

    def test_save_and_load(self) -> None:
        qm = QuestManager()
        qm.start_chronicle("supply_run", "depart")
        qm.set_flag("supply_run", "ambushed", True)
        qm.advance_stage("supply_run", "deliver")
        qm.start_chronicle("intel_op", "gather")
        qm.complete_chronicle("intel_op")

        with tempfile.NamedTemporaryFile(mode="w", suffix=".json", delete=False) as f:
            save_path = Path(f.name)

        try:
            qm.save(save_path)

            qm2 = QuestManager()
            qm2.load(save_path)

            p1 = qm2.get_progress("supply_run")
            assert p1 is not None
            assert p1.current_stage == "deliver"
            assert p1.flags["ambushed"] is True
            assert p1.completed is False

            p2 = qm2.get_progress("intel_op")
            assert p2 is not None
            assert p2.completed is True
        finally:
            save_path.unlink(missing_ok=True)

    def test_load_nonexistent_file(self) -> None:
        qm = QuestManager()
        qm.load(Path("/tmp/does_not_exist_12345.json"))
        assert qm.chronicles == {}
