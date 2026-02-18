from __future__ import annotations
import json
from pathlib import Path
from typing import Any, Dict, List, Optional


class DialogueTree:
    """
    Extended dialogue system supporting 'effect' and 'condition' fields.

    Conditions:
        has_<item>             - True if item is in inventory
        flag_<name>            - True if flag is set
        faction_<Name>_<N>     - True if faction standing >= N

    Effects:
        faction   - {"FactionName": delta}  modify faction standings
        add_item  - "item_name"             add item to inventory
        remove_item - "item_name"           remove item from inventory
        set_flag  - {"flag": value}         set game flags
    """

    def __init__(self, path: str | Path, game_state: Dict[str, Any]) -> None:
        self.path = Path(path)
        with self.path.open("r", encoding="utf-8") as f:
            data = json.load(f)
        self.nodes: Dict[str, Dict[str, Any]] = data["nodes"]
        self.start_id: str = data["start"]
        self.current_id: Optional[str] = self.start_id
        self.game_state = game_state

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
        if condition.startswith("has_"):
            item = condition[4:]
            return item in self.game_state.get("inventory", [])
        if condition.startswith("flag_"):
            flag = condition[5:]
            return self.game_state.get("flags", {}).get(flag, False)
        if condition.startswith("faction_"):
            # e.g. "faction_Caldari_5" -> faction="Caldari", threshold=5
            parts = condition.split("_")
            if len(parts) >= 3:
                faction = parts[1]
                try:
                    threshold = int(parts[2])
                except ValueError:
                    return False
                standing = self.game_state.get("factions", {}).get(faction, 0)
                return standing >= threshold
        return False

    def advance(self, choice_index: int) -> Optional[Dict[str, Any]]:
        choices = self.choices()
        if not choices or choice_index < 0 or choice_index >= len(choices):
            self.current_id = None
            return None
        choice = choices[choice_index]
        effect = choice.get("effect")
        if effect:
            self.apply_effect(effect)
        next_id = choice.get("next")
        self.current_id = next_id if next_id in self.nodes else None
        return choice

    def apply_effect(self, effect: Dict[str, Any]) -> None:
        # Faction standing changes: {"faction": {"Caldari Navy": 5}}
        if "faction" in effect:
            for fac, delta in effect["faction"].items():
                self.game_state.setdefault("factions", {}).setdefault(fac, 0)
                self.game_state["factions"][fac] += delta

        # Add item to inventory: {"add_item": "item_name"}
        if "add_item" in effect:
            self.game_state.setdefault("inventory", []).append(effect["add_item"])

        # Remove item from inventory: {"remove_item": "item_name"}
        if "remove_item" in effect:
            inv = self.game_state.get("inventory", [])
            item = effect["remove_item"]
            if item in inv:
                inv.remove(item)

        # Set flags: {"set_flag": {"flag_name": value}}
        if "set_flag" in effect:
            for flag, value in effect["set_flag"].items():
                self.game_state.setdefault("flags", {})[flag] = value

    def is_finished(self) -> bool:
        return self.current_id is None
