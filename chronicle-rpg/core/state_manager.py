from __future__ import annotations
from typing import List

class GameState:
    """Base class for any game state/scene (menus, maps, dialogs, etc.)."""
    def handle_event(self, event) -> None: pass
    def update(self, dt: float) -> None: pass
    def draw(self, screen) -> None: pass

class GameStateManager:
    """Simple stack-based state manager for game scenes and menus."""
    def __init__(self) -> None:
        self.stack: List[GameState] = []
    def push(self, state: GameState) -> None: self.stack.append(state)
    def pop(self) -> None: 
        if self.stack: self.stack.pop()
    def switch(self, state: GameState) -> None:
        if self.stack: self.stack.pop()
        self.stack.append(state)
    def current(self) -> GameState | None:
        if self.stack: return self.stack[-1]
        return None
    def handle_event(self, event) -> None:
        state = self.current()
        if state: state.handle_event(event)
    def update(self, dt: float) -> None:
        state = self.current()
        if state: state.update(dt)
    def draw(self, screen) -> None:
        state = self.current()
        if state: state.draw(screen)