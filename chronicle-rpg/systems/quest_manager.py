from __future__ import annotations
from dataclasses import dataclass, field
from typing import Dict, Optional, Any
import json
from pathlib import Path


@dataclass
class ChronicleProgress:
    chronicle_id: str
    current_stage: str
    completed: bool = False
    flags: Dict[str, Any] = field(default_factory=dict)


class QuestManager:
    def __init__(self) -> None:
        self.chronicles: Dict[str, ChronicleProgress] = {}

    def start_chronicle(self, chronicle_id: str, start_stage: str) -> None:
        self.chronicles[chronicle_id] = ChronicleProgress(chronicle_id, start_stage)

    def get_progress(self, chronicle_id: str) -> Optional[ChronicleProgress]:
        return self.chronicles.get(chronicle_id)

    def complete_chronicle(self, chronicle_id: str) -> None:
        progress = self.chronicles.get(chronicle_id)
        if progress:
            progress.completed = True

    def set_flag(self, chronicle_id: str, flag: str, value: Any = True) -> None:
        progress = self.chronicles.get(chronicle_id)
        if progress:
            progress.flags[flag] = value

    def advance_stage(self, chronicle_id: str, new_stage: str) -> None:
        progress = self.chronicles.get(chronicle_id)
        if progress:
            progress.current_stage = new_stage

    def save(self, path: str | Path) -> None:
        """Save all chronicle progress to a JSON file."""
        path = Path(path)
        data = {}
        for cid, progress in self.chronicles.items():
            data[cid] = {
                "chronicle_id": progress.chronicle_id,
                "current_stage": progress.current_stage,
                "completed": progress.completed,
                "flags": progress.flags,
            }
        path.parent.mkdir(parents=True, exist_ok=True)
        with path.open("w", encoding="utf-8") as f:
            json.dump(data, f, indent=2)

    def load(self, path: str | Path) -> None:
        """Load chronicle progress from a JSON file. Silently skips if file not found."""
        path = Path(path)
        if not path.exists():
            return
        with path.open("r", encoding="utf-8") as f:
            data = json.load(f)
        self.chronicles.clear()
        for cid, entry in data.items():
            self.chronicles[cid] = ChronicleProgress(
                chronicle_id=entry["chronicle_id"],
                current_stage=entry["current_stage"],
                completed=entry.get("completed", False),
                flags=entry.get("flags", {}),
            )
