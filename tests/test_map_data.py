from __future__ import annotations

import json
import tempfile
from pathlib import Path
from unittest.mock import MagicMock

import sys

# Provide a minimal pygame stub so tests work without a display
pygame_mock = MagicMock()


class FakeRect:
    """Minimal Rect replacement for testing without pygame display init."""

    def __init__(self, x: int, y: int, w: int, h: int) -> None:
        self.x = x
        self.y = y
        self.w = w
        self.h = h

    def collidepoint(self, px: int, py: int) -> bool:
        return self.x <= px < self.x + self.w and self.y <= py < self.y + self.h

    def __eq__(self, other: object) -> bool:
        if not isinstance(other, FakeRect):
            return NotImplemented
        return (self.x, self.y, self.w, self.h) == (other.x, other.y, other.w, other.h)


pygame_mock.Rect = FakeRect
sys.modules.setdefault("pygame", pygame_mock)

from world.maps.map_data import MapData  # noqa: E402

SAMPLE_MAP = {
    "name": "Test Station",
    "width": 10,
    "height": 8,
    "tile_size": 32,
    "collisions": [[2, 3], [4, 5]],
    "npcs": [
        {"id": "npc1", "name": "Agent", "position": [5, 5], "dialogue": "test.json"}
    ],
    "interactables": [
        {"id": "door", "position": [0, 4], "type": "door", "action": "open"}
    ],
    "events": [{"id": "ambience", "type": "ambient", "trigger": "on_enter"}],
}


def _write_map(data: dict) -> Path:
    f = tempfile.NamedTemporaryFile(mode="w", suffix=".json", delete=False)
    json.dump(data, f)
    f.close()
    return Path(f.name)


class TestMapData:
    def test_load_basic_properties(self) -> None:
        path = _write_map(SAMPLE_MAP)
        try:
            m = MapData(path)
            assert m.name == "Test Station"
            assert m.width == 10
            assert m.height == 8
            assert m.tile_size == 32
        finally:
            path.unlink()

    def test_default_name(self) -> None:
        data = {**SAMPLE_MAP}
        del data["name"]
        path = _write_map(data)
        try:
            m = MapData(path)
            assert m.name == "Unknown Map"
        finally:
            path.unlink()

    def test_default_tile_size(self) -> None:
        data = {**SAMPLE_MAP}
        del data["tile_size"]
        path = _write_map(data)
        try:
            m = MapData(path)
            assert m.tile_size == 32
        finally:
            path.unlink()

    def test_collision_rects(self) -> None:
        path = _write_map(SAMPLE_MAP)
        try:
            m = MapData(path)
            assert len(m.collision_rects) == 2
            # First collision at grid (2,3) -> pixel (64, 96)
            r = m.collision_rects[0]
            assert r.x == 64
            assert r.y == 96
        finally:
            path.unlink()

    def test_npcs_loaded(self) -> None:
        path = _write_map(SAMPLE_MAP)
        try:
            m = MapData(path)
            assert len(m.npcs) == 1
            assert m.npcs[0]["name"] == "Agent"
        finally:
            path.unlink()

    def test_interactables_loaded(self) -> None:
        path = _write_map(SAMPLE_MAP)
        try:
            m = MapData(path)
            assert len(m.interactables) == 1
            assert m.interactables[0]["type"] == "door"
        finally:
            path.unlink()

    def test_events_loaded(self) -> None:
        path = _write_map(SAMPLE_MAP)
        try:
            m = MapData(path)
            assert len(m.events) == 1
        finally:
            path.unlink()

    def test_is_blocked_with_collision_rects(self) -> None:
        path = _write_map(SAMPLE_MAP)
        try:
            m = MapData(path)
            assert m.is_blocked((2, 3)) is True
            assert m.is_blocked((4, 5)) is True
            assert m.is_blocked((0, 0)) is False
        finally:
            path.unlink()

    def test_is_blocked_with_collision_mask(self) -> None:
        data = {
            "name": "Mask Map",
            "width": 3,
            "height": 3,
            "tile_size": 32,
            "collision_mask": [
                [0, 1, 0],
                [0, 0, 0],
                [1, 0, 0],
            ],
        }
        path = _write_map(data)
        try:
            m = MapData(path)
            assert m.is_blocked((1, 0)) is True  # mask[0][1] == 1
            assert m.is_blocked((0, 2)) is True  # mask[2][0] == 1
            assert m.is_blocked((0, 0)) is False
        finally:
            path.unlink()

    def test_is_blocked_mask_out_of_bounds(self) -> None:
        data = {
            "name": "Small",
            "width": 2,
            "height": 2,
            "tile_size": 32,
            "collision_mask": [[0, 0], [0, 0]],
        }
        path = _write_map(data)
        try:
            m = MapData(path)
            assert m.is_blocked((99, 99)) is False
        finally:
            path.unlink()

    def test_world_pos(self) -> None:
        path = _write_map(SAMPLE_MAP)
        try:
            m = MapData(path)
            rect = m.world_pos((3, 4))
            assert rect.x == 96
            assert rect.y == 128
            assert rect.w == 32
        finally:
            path.unlink()

    def test_empty_collisions(self) -> None:
        data = {"name": "Empty", "width": 5, "height": 5, "tile_size": 32}
        path = _write_map(data)
        try:
            m = MapData(path)
            assert m.collision_rects == []
            assert m.is_blocked((2, 2)) is False
        finally:
            path.unlink()
