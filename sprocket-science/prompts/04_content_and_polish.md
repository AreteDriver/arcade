# Claude Code Prompt: Phase 4 — Content, Inventor Mode & Polish

## Context
Read `docs/CONCEPT.md` for full design. Phases 1-3 are complete: core engine, visual feedback, and Discovery Mode with World 1.

## Task
Expand content (Worlds 2-4), build Inventor Mode (sandbox), and polish for Android release.

## Requirements

### 1. Remaining Sci-Fi Components
Implement all Tier 2 and Tier 3 components from the concept doc. Each needs:
- Full physics behavior
- Port definitions (typed I/O)
- Parameter set with sensible ranges
- Visual feedback for all states (idle, active, broken, overloaded)
- Unique sound profile
- Component tray icon

Priority components for World 2-4 machines:
- Plasma Conduit, Gravity Node, Chrono Spring, Phase Gate, Warp Belt
- Fusion Core, Holo Projector, Dimensional Splitter
- Sound Forge (converts energy to musical tones — kids will love this)
- Cloud Weaver (particle sculptor — sandbox star)

### 2. Worlds 2-4 Machine Definitions
Build 12 more machine definitions (4 per world) following the patterns in CONCEPT.md:

**World 2: Sky Factory** — Focus on flow management and environmental themes
**World 3: Dream Workshop** — Focus on signal/logic and creative themes  
**World 4: Impossible Lab** — Combine all systems, highest complexity

Each machine needs:
- MachineDefinition .tres resource
- Challenge logic (broken/miscalibrated/incomplete/overloaded)
- Intro and success dialog
- Component unlock rewards
- 3-star rating criteria

### 3. Inventor Mode (`inventor_mode.tscn`)
Full sandbox experience:

**Component Tray:**
- Shows only unlocked components (earned through Discovery)
- Searchable/filterable by type (mechanical, flow, force, logic, exotic)
- Favorites system (long press to star)

**Machine Purpose Selector:**
- Optional: player defines what machine does via fun multiple-choice
- "My machine will: [make music / sort things / launch stuff / do magic / surprise me]"
- Sets a loose theme but doesn't constrain building
- Purely for flavor and save file metadata

**Building:**
- Full canvas with unlimited (within performance budget) component placement
- All wire connection and parameter features from core engine
- Undo/redo stack (essential for kids who make mistakes)
- Duplicate component (long press → "copy")
- Multi-select and move (box select or shift-tap)

**Testing:**
- Play/pause/reset as in Discovery
- Add "test objects" — balls, blocks, particles to throw into the machine
- Slow-mo and fast-forward controls
- Optional: trace mode showing flow paths highlighted

**Saving:**
- Name your machine (on-screen keyboard)
- Auto-thumbnail from current camera view
- Save to user://inventions/ as JSON
- Load screen shows grid of saved machines with thumbnails
- Delete with confirmation

### 4. Component Tooltip System
When a component is tapped in the tray (before placing):
- Show a tooltip card with:
  - Component name and icon
  - Brief fun description ("The Quantum Coupler sends energy through the quantum realm!")
  - Port diagram (visual showing inputs/outputs and their types)
  - Parameter list with ranges
- Helps kids learn what components do before placing them

### 5. Settings Screen
- Master volume slider
- SFX volume slider  
- Music volume slider
- Reduce motion toggle (accessibility)
- Grid snap toggle
- Reset progress (with confirmation dialog)
- Credits

### 6. Main Menu
- Title: "Machine Shop of Tomorrow" with animated background machine
- "Discovery" button → World select
- "Inventor" button → Inventor Mode
- "My Machines" button → Saved inventions gallery
- Settings gear icon

### 7. Android Export Preparation
- Configure project.godot for Android:
  - Landscape orientation locked
  - Touch input settings
  - Display scaling (responsive to device size)
  - Min SDK version
- App icon (simple, bold, recognizable)
- Splash screen
- Performance profiling on target device
- Test on at least one physical Android device
- Build signed APK

### 8. Polish Pass
- Loading transitions between screens (fade or slide)
- Consistent button styles and sizing for touch (min 48dp touch targets)
- Error handling: graceful fallback if save files are corrupted
- Empty state screens ("No saved machines yet — build one!")
- Haptic feedback on mobile for key interactions (place, connect, play)

## Technical Notes
- World 2-4 machines should escalate in component count and connection complexity
- Inventor Mode undo/redo: use Command pattern (store actions as objects)
- Save files should be forward-compatible (version field, ignore unknown keys)
- Test with Android export early — don't wait until everything is built
- Performance: profile with Godot's built-in profiler, watch physics body count
- Consider AsyncResourceLoader for machine definitions (prevent frame drops on load)

## Output
After this phase, the game is feature-complete:
1. Full Discovery Mode (4 worlds × 4 machines = 16 levels)
2. Full Inventor Mode with save/load
3. All components from Tiers 1-3 implemented
4. Main menu, settings, machine gallery
5. Android APK ready for device testing
6. Polished transitions and touch interactions
