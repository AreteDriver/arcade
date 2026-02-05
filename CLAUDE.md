# YokaiBlade - Project Instructions

## Project Overview
Sekiro-inspired action game featuring Japanese yokai bosses. Each boss teaches a specific combat lesson.

**Engine**: Unity (LTS)
**Language**: C#
**Pattern**: Data-driven combat with ScriptableObjects

---

## Architecture

### Core Systems (Assets/Core/)
- **Boss/** — Individual boss implementations (KasaObake, Tanuki, Oni, etc.)
- **Combat/** — Deflect system, damage, attack runner
- **Player/** — Player controller and state

### Design Philosophy
- Each boss teaches ONE core mechanic
- Telegraph semantics are global (consistent across all bosses)
- Data-driven AttackDefinition via ScriptableObjects
- Fixed timestep for combat logic

---

## Boss Roster (Tier 1 - Teaching)

| Boss | Lesson | Key Mechanic |
|------|--------|--------------|
| Kasa-Obake | Rhythm | 1-2-3 hop pattern, attack on beat 3 |
| Hitotsume-Kozo | Aggression | Pressure timer (regen if passive) |
| Shirime | Positioning | Must attack from behind |
| Tanuki | Observation | Disguise phases |
| Chochin-Obake | Resource | Capacitor/energy management |

---

## Development Workflow

```bash
# Tests (Unity Test Framework)
# Run via Unity Editor: Window > General > Test Runner

# Or command line (if Unity CLI configured)
unity -runTests -projectPath . -testResults results.xml
```

---

## Code Conventions
- C# naming: PascalCase for public, _camelCase for private fields
- One class per file
- State machines for boss AI
- ScriptableObjects for attack definitions
- Unit tests in Assets/Tests/EditMode/

---

## Token Economy for Unity
- 60 FPS tuning baseline
- Fixed timestep for combat logic
- No refactors unless required for correctness
- Telegraph semantics are global truth (cannot override per boss)
