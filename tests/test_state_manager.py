from __future__ import annotations

from core.state_manager import GameState, GameStateManager


class DummyState(GameState):
    def __init__(self, name: str = "dummy") -> None:
        self.name = name
        self.events: list = []
        self.updated = False
        self.drawn = False

    def handle_event(self, event) -> None:
        self.events.append(event)

    def update(self, dt: float) -> None:
        self.updated = True

    def draw(self, screen) -> None:
        self.drawn = True


class TestGameStateManager:
    def test_starts_empty(self) -> None:
        mgr = GameStateManager()
        assert mgr.current() is None

    def test_push(self) -> None:
        mgr = GameStateManager()
        s1 = DummyState("menu")
        mgr.push(s1)
        assert mgr.current() is s1

    def test_push_stacks(self) -> None:
        mgr = GameStateManager()
        s1 = DummyState("menu")
        s2 = DummyState("game")
        mgr.push(s1)
        mgr.push(s2)
        assert mgr.current() is s2

    def test_pop(self) -> None:
        mgr = GameStateManager()
        s1 = DummyState("menu")
        s2 = DummyState("game")
        mgr.push(s1)
        mgr.push(s2)
        mgr.pop()
        assert mgr.current() is s1

    def test_pop_empty_is_safe(self) -> None:
        mgr = GameStateManager()
        mgr.pop()  # should not raise
        assert mgr.current() is None

    def test_switch(self) -> None:
        mgr = GameStateManager()
        s1 = DummyState("menu")
        s2 = DummyState("game")
        mgr.push(s1)
        mgr.switch(s2)
        assert mgr.current() is s2
        mgr.pop()
        assert mgr.current() is None  # stack only had one item

    def test_switch_on_empty_pushes(self) -> None:
        mgr = GameStateManager()
        s1 = DummyState("menu")
        mgr.switch(s1)
        assert mgr.current() is s1

    def test_handle_event_delegates(self) -> None:
        mgr = GameStateManager()
        s1 = DummyState()
        mgr.push(s1)
        mgr.handle_event("test_event")
        assert s1.events == ["test_event"]

    def test_handle_event_empty_is_safe(self) -> None:
        mgr = GameStateManager()
        mgr.handle_event("evt")  # should not raise

    def test_update_delegates(self) -> None:
        mgr = GameStateManager()
        s1 = DummyState()
        mgr.push(s1)
        mgr.update(0.016)
        assert s1.updated is True

    def test_update_empty_is_safe(self) -> None:
        mgr = GameStateManager()
        mgr.update(0.016)  # should not raise

    def test_draw_delegates(self) -> None:
        mgr = GameStateManager()
        s1 = DummyState()
        mgr.push(s1)
        mgr.draw("screen")
        assert s1.drawn is True

    def test_draw_empty_is_safe(self) -> None:
        mgr = GameStateManager()
        mgr.draw("screen")  # should not raise
