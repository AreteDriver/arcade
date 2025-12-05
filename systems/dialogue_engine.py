from __future__ import annotations
import json
from pathlib import Path
from typing import Any, Dict, List, Optional

class DialogueTree:
    """
    Extended dialogue system supporting 'effect' and 'condition' fields.
    """
    def __init__(self, path: str | Path, game_state: Dict[str, Any]) -> None:
        self.path = Path(path)
        with self.path.open("r", encoding="utf-8") as f:
            data = json.load(f)
        self.nodes: Dict[str, Dict[str, Any]] = data["nodes"]
        self.start_id: str = data["start"]
        self.current_id: Optional[str] = self.start_id
        self.game_state = game_state  # Reference to player's inventory, flags, factions, etc.

    def reset(self) -> None:
        self.current_id = self.start_id

    def current_node(self) -> Optional[Dict[str, Any]]:
        if self.current_id is None:
            return None
        return self.nodes.get(self.current_id)

    def choices(self) -> List[Dict[str, Any]]:
        """Returns only choices the player can select (based on conditions)."""
        node = self.current_node()
        if not node:
            return []
        result = []
        for choice in node.get("choices", []):
            condition = choice.get("condition")
            if condition is None or self.check_condition(condition):
                result.append(choice)
        return result

    def check_condition(self, condition: str) -> bool:
        # Example condition checks; customize as needed.
        if condition.startswith("has_"):
            item = condition[4:]
            return item in self.game_state.get("inventory", [])
        if condition.startswith("flag_"):
            flag = condition[5:]
            return self.game_state.get("flags", {}).get(flag, False)
        # Extend with more condition types as needed.
        return False

    def advance(self, choice_index: int) -> Optional[Dict[str, Any]]:
        choices = self.choices()
        if not choices or choice_index < 0 or choice_index >= len(choices):
            self.current_id = None
            return None
        choice = choices[choice_index]
        # Apply effect if present
        effect = choice.get("effect")
        if effect:
            self.apply_effect(effect)
        next_id = choice.get("next")
        self.current_id = next_id if next_id in self.nodes else None
        return choice

    def apply_effect(self, effect: Dict[str, Any]) -> None:
        # Example effect handler – extend as needed
        # Faction: {"faction": {"Caldari": -1}}
        if "faction" in effect:
            for fac, delta in effect["faction"].items():
                self.game_state.setdefault("factions", {}).setdefault(fac, 0)
                self.game_state["factions"][fac] += delta
        # Add more effect handling for flags, items, etc.

    def is_finished(self) -> bool:
        return self.current_id is None
