from __future__ import annotations
import json
from pathlib import Path
from typing import Any, Dict, List, Tuple, Optional
import pygame

class MapData:
    def __init__(self, path: str | Path) -> None:
        path = Path(path)
        with path.open("r", encoding="utf-8") as f:
            data: Dict[str, Any] = json.load(f)
        self.name: str = data.get("name", "Unknown Map")
        self.width: int = data["width"]
        self.height: int = data["height"]
        self.tile_size: int = data.get("tile_size", 32)
        self.layers: Optional[List[Dict[str, Any]]] = data.get("layers", None)
        self.collision_mask = data.get("collision_mask", None)
        self.collision_rects: List[pygame.Rect] = [
            pygame.Rect(x * self.tile_size, y * self.tile_size, self.tile_size, self.tile_size)
            for x, y in data.get("collisions", [])
        ]
        self.npcs: List[Dict[str, Any]] = data.get("npcs", [])
        self.interactables: List[Dict[str, Any]] = data.get("interactables", [])
        self.events: List[Dict[str, Any]] = data.get("events", [])
    def world_pos(self, grid_pos: Tuple[int, int]) -> pygame.Rect:
        x, y = grid_pos
        return pygame.Rect(x * self.tile_size, y * self.tile_size, self.tile_size, self.tile_size)
    def is_blocked(self, grid_pos: Tuple[int, int]) -> bool:
        x, y = grid_pos
        if self.collision_mask:
            try: return self.collision_mask[y][x] == 1
            except IndexError: return False
        return any(rect.collidepoint(x * self.tile_size, y * self.tile_size) for rect in self.collision_rects)