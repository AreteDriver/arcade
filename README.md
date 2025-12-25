# EVE Chronicle RPG

**A Python RPG framework set in the EVE Online universe.**

[![MIT License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![Python 3.12+](https://img.shields.io/badge/Python-3.12+-blue.svg)](https://www.python.org/downloads/)
[![Pygame 2.5+](https://img.shields.io/badge/Pygame-2.5+-red.svg)](https://www.pygame.org/)

---

![EVE Chronicle RPG Screenshot](docs/screenshot.png)

> **Screenshot Instructions:** Capture gameplay showing:
> 1. A dialogue box with branching choices
> 2. Faction standing indicators (Caldari, Amarr, etc.)
> 3. A tilemap environment (station interior or planet surface)
> 4. Quest/Chronicle tracker in the UI
>
> For a GIF: Record navigating a dialogue tree with faction consequences.

---

## Overview

EVE Chronicle RPG is a game framework for building story-driven RPGs in the EVE Online universe. It provides core systems that handle the heavy lifting of RPG development:

- **Dialogue Trees** - Branching conversations with conditions and effects
- **Quest/Chronicle System** - Multi-stage mission tracking with flags
- **State Management** - Stack-based scene and menu system
- **Tilemap Support** - Grid-based world with collision and NPCs

Build your own stories in New Eden. Negotiate with faction agents. Make choices that matter.

---

## Features

### Dialogue Engine
- JSON-based branching dialogue trees
- **Conditional choices** - Options appear based on inventory, flags, or faction standing
- **Effects system** - Choices modify faction standings, set flags, grant items
- Extensible condition/effect handlers

### Chronicle System
- Multi-stage quest tracking
- Arbitrary flag storage per chronicle
- Stage progression and completion tracking
- Ready for save/load integration

### State Manager
- Stack-based scene management
- Push/pop/switch between game states
- Layer dialogues over gameplay
- Clean separation of menu, world, and conversation states

### Map System
- Tilemap loading from JSON
- Grid-based collision detection
- NPC placement with dialogue references
- Interactable objects and events

---

## Installation

### Requirements
- Python 3.12+
- Pygame 2.5+

### Quick Start

```bash
# Clone the repository
git clone https://github.com/AreteDriver/EVE_ChronicleRPG.git
cd EVE_ChronicleRPG

# Install dependencies
pip install -r requirements.txt

# Run the demo
python main.py
```

### Virtual Environment (Recommended)

```bash
python -m venv venv
source venv/bin/activate  # Linux/Mac
# or: venv\Scripts\activate  # Windows

pip install -r requirements.txt
python main.py
```

---

## Usage

### Basic Game Loop

```python
import pygame
from core.state_manager import GameStateManager, GameState

class MainMenuState(GameState):
    def handle_event(self, event):
        if event.type == pygame.KEYDOWN:
            if event.key == pygame.K_RETURN:
                # Start game
                pass

    def draw(self, screen):
        # Render menu
        pass

# Initialize
pygame.init()
screen = pygame.display.set_mode((800, 600))
clock = pygame.time.Clock()
state_manager = GameStateManager()
state_manager.push(MainMenuState())

# Game loop
running = True
while running:
    dt = clock.tick(60) / 1000.0

    for event in pygame.event.get():
        if event.type == pygame.QUIT:
            running = False
        state_manager.handle_event(event)

    state_manager.update(dt)
    state_manager.draw(screen)
    pygame.display.flip()
```

### Creating Dialogues

**dialogue_agent.json:**
```json
{
  "start": "greeting",
  "nodes": {
    "greeting": {
      "text": "Welcome to Jita, capsuleer. I represent Caldari Navy interests here.",
      "choices": [
        {
          "text": "I'm looking for work.",
          "next": "work_offer"
        },
        {
          "text": "I have intel on Gallente movements.",
          "next": "intel",
          "condition": "has_gallente_intel"
        },
        {
          "text": "Never mind.",
          "next": null
        }
      ]
    },
    "work_offer": {
      "text": "We need supplies delivered to our outpost in Nonni. Interested?",
      "choices": [
        {
          "text": "I'll do it.",
          "next": "accept_mission",
          "effect": { "faction": { "Caldari Navy": 5 } }
        },
        {
          "text": "What's the pay?",
          "next": "negotiate"
        }
      ]
    },
    "intel": {
      "text": "Excellent. This information is valuable. The State thanks you.",
      "choices": [
        {
          "text": "Glad to help.",
          "next": null,
          "effect": {
            "faction": { "Caldari Navy": 10, "Gallente Federation": -5 }
          }
        }
      ]
    }
  }
}
```

**Loading the dialogue:**
```python
from systems.dialogue_engine import DialogueTree

game_state = {
    "inventory": ["gallente_intel"],
    "flags": {},
    "factions": {"Caldari Navy": 0}
}

dialogue = DialogueTree("data/dialogue_agent.json", game_state)

# Get current text
node = dialogue.current_node()
print(node["text"])

# Get available choices (filtered by conditions)
choices = dialogue.choices()
for i, choice in enumerate(choices):
    print(f"{i + 1}. {choice['text']}")

# Player selects choice 0
dialogue.advance(0)

# Check faction changes
print(game_state["factions"])  # {"Caldari Navy": 5}
```

### Managing Quests/Chronicles

```python
from systems.quest_manager import QuestManager

quest_mgr = QuestManager()

# Start a chronicle
quest_mgr.start_chronicle("caldari_supply_run", "travel_to_nonni")

# Check progress
progress = quest_mgr.get_progress("caldari_supply_run")
print(progress.current_stage)  # "travel_to_nonni"

# Player reaches destination
quest_mgr.advance_stage("caldari_supply_run", "deliver_cargo")

# Set a flag (e.g., player was ambushed)
quest_mgr.set_flag("caldari_supply_run", "ambushed", True)

# Complete the chronicle
quest_mgr.complete_chronicle("caldari_supply_run")
print(progress.completed)  # True
```

### Loading Maps

**maps/jita_station.json:**
```json
{
  "name": "Jita 4-4 Trading Hub",
  "width": 30,
  "height": 20,
  "tile_size": 32,
  "collisions": [[5, 5], [5, 6], [5, 7]],
  "npcs": [
    {
      "id": "caldari_agent",
      "name": "Commander Ishukone",
      "position": [10, 8],
      "dialogue": "dialogue_agent.json"
    }
  ],
  "interactables": [
    {
      "id": "market_terminal",
      "position": [15, 10],
      "type": "terminal",
      "action": "open_market"
    }
  ]
}
```

**Loading the map:**
```python
from world.maps.map_data import MapData

map_data = MapData("maps/jita_station.json")

print(map_data.name)  # "Jita 4-4 Trading Hub"

# Check if a tile is blocked
if map_data.is_blocked((5, 5)):
    print("Can't walk there!")

# Get NPCs
for npc in map_data.npcs:
    print(f"{npc['name']} at {npc['position']}")
```

---

## Project Structure

```
EVE_ChronicleRPG/
├── core/
│   └── state_manager.py      # GameState, GameStateManager
├── systems/
│   ├── dialogue_engine.py    # DialogueTree with conditions/effects
│   └── quest_manager.py      # ChronicleProgress, QuestManager
├── world/
│   └── maps/
│       └── map_data.py       # MapData tilemap loader
├── data/                     # Your game content (create this)
│   ├── dialogues/
│   └── maps/
├── main.py                   # Entry point
├── requirements.txt
├── LICENSE
└── README.md
```

---

## API Reference

### GameState

Base class for all game scenes.

```python
class GameState:
    def handle_event(self, event) -> None: ...
    def update(self, dt: float) -> None: ...
    def draw(self, screen) -> None: ...
```

### GameStateManager

Stack-based state management.

| Method | Description |
|--------|-------------|
| `push(state)` | Add state to top of stack |
| `pop()` | Remove top state |
| `switch(state)` | Replace top state |
| `current()` | Get current state |

### DialogueTree

JSON-based dialogue system.

| Method | Description |
|--------|-------------|
| `current_node()` | Get current dialogue node |
| `choices()` | Get available choices (filtered) |
| `advance(index)` | Select a choice, apply effects |
| `is_finished()` | Check if dialogue ended |
| `reset()` | Return to start node |

### QuestManager

Chronicle/quest tracking.

| Method | Description |
|--------|-------------|
| `start_chronicle(id, stage)` | Begin a new chronicle |
| `get_progress(id)` | Get ChronicleProgress |
| `advance_stage(id, stage)` | Move to next stage |
| `set_flag(id, flag, value)` | Set arbitrary flag |
| `complete_chronicle(id)` | Mark as complete |

### MapData

Tilemap data loader.

| Property | Description |
|----------|-------------|
| `name` | Map display name |
| `width`, `height` | Grid dimensions |
| `tile_size` | Pixels per tile |
| `npcs` | List of NPC definitions |
| `collision_rects` | Blocked areas |

---

## Extending the Framework

### Custom Conditions

```python
def check_condition(self, condition: str) -> bool:
    # Existing conditions
    if condition.startswith("has_"):
        item = condition[4:]
        return item in self.game_state.get("inventory", [])

    if condition.startswith("flag_"):
        flag = condition[5:]
        return self.game_state.get("flags", {}).get(flag, False)

    # Add your own
    if condition.startswith("faction_"):
        # e.g., "faction_caldari_5" = Caldari standing >= 5
        parts = condition.split("_")
        faction = parts[1].title()
        threshold = int(parts[2])
        standing = self.game_state.get("factions", {}).get(faction, 0)
        return standing >= threshold

    return False
```

### Custom Effects

```python
def apply_effect(self, effect: Dict[str, Any]) -> None:
    # Faction changes
    if "faction" in effect:
        for fac, delta in effect["faction"].items():
            self.game_state.setdefault("factions", {}).setdefault(fac, 0)
            self.game_state["factions"][fac] += delta

    # Add items
    if "add_item" in effect:
        self.game_state.setdefault("inventory", []).append(effect["add_item"])

    # Set flags
    if "set_flag" in effect:
        for flag, value in effect["set_flag"].items():
            self.game_state.setdefault("flags", {})[flag] = value
```

---

## Roadmap

### Planned Features
- [ ] Save/load system for chronicles and game state
- [ ] Combat system integration
- [ ] Ship management (hangar, fitting)
- [ ] ISK economy and trading
- [ ] Faction warfare mechanics
- [ ] Web deployment via Pygbag

### Known Limitations
- No built-in rendering (bring your own sprites/tiles)
- Save system is stubbed, not implemented
- Single-player focused

---

## Contributing

Contributions welcome! Areas that need work:

- **Content** - Dialogues, chronicles, maps
- **Systems** - Combat, trading, skills
- **Art** - Tilesets, character sprites, UI elements
- **Documentation** - Tutorials, examples

### Development Setup

```bash
git clone https://github.com/AreteDriver/EVE_ChronicleRPG.git
cd EVE_ChronicleRPG
python -m venv venv
source venv/bin/activate
pip install -r requirements.txt
```

---

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## Disclaimer

**EVE Chronicle RPG is not affiliated with or endorsed by CCP Games.**

EVE Online and all associated names, factions, and lore are registered trademarks of CCP hf. This is an independent fan project created out of love for the EVE universe. No game assets from EVE Online are included in this repository.

---

## Acknowledgments

- **CCP Games** - For creating the rich lore of New Eden
- **Pygame Community** - For the excellent game development framework
- **EVE Lore Community** - For keeping the chronicles alive

---

<p align="center">
  <em>"In the beginning, there was void."</em>
  <br><br>
  <strong>Write your own chronicle. o7</strong>
</p>
