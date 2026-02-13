# Claude Code Prompt: Phase 2 — Juice & Visual Feedback

## Context
Read `docs/CONCEPT.md` for full design. Phase 1 core engine is complete. We have base components, port system, component graph, drag-and-drop, wire connections, and simulation controls working.

## Task
Add visual and audio feedback systems that make every interaction feel satisfying. This is what makes the game fun for kids — immediate, exaggerated responses to every action.

## Requirements

### 1. Visual Feedback System (`visual_feedback_manager.gd`)
Create a centralized feedback system that components can call into:

```gdscript
# Any component can request visual feedback
VisualFeedbackManager.pulse(node, color, duration)
VisualFeedbackManager.shake(node, intensity, duration)
VisualFeedbackManager.spark(position, color, count)
VisualFeedbackManager.glow(node, color, intensity)
VisualFeedbackManager.celebrate(position)  # Rainbow burst for success
VisualFeedbackManager.warning(node)        # Red pulse for overload
VisualFeedbackManager.break_effect(node)   # Sparks + smoke
```

### 2. Flow Visualization
When flow passes through pipes/conduits:
- Animated particles traveling along the wire/pipe path
- Color matches port type (blue for flow, yellow for energy, green for signal)
- Speed reflects the flow rate parameter
- Accumulation visual when blocked (particles pile up)

### 3. Component State Visuals
Each state needs distinct visual treatment:
- **IDLE** — Slightly desaturated, static
- **ACTIVE** — Full color, subtle idle animation (gentle bob or hum)
- **BROKEN** — Cracked overlay, spark particles, slight tilt, sad face emoji overlay
- **OVERLOADED** — Red pulsing glow, vibration/shake, warning particles, steam

### 4. Wire Animation
- Wires pulse with energy traveling from output to input
- Pulse speed matches the flow/energy rate
- Disconnected wires spark at the open end
- Wire thickness reflects load/throughput

### 5. Interaction Feedback
- **Place component** — Satisfying "pop" scale animation (scale from 0.5 to 1.1 to 1.0)
- **Connect wire** — Snap animation + brief glow at both ports
- **Adjust slider** — Component reacts in real-time (fan spins faster, ramp tilts)
- **Delete** — Shrink + fade + puff of particles
- **Simulation start** — Wave of activation ripples through connected components
- **Simulation reset** — Everything gently floats back to starting position

### 6. Particle Systems
Create reusable GPUParticles2D scenes:
- `spark_particles.tscn` — Short burst, yellow/orange, for connections and breaks
- `flow_particles.tscn` — Continuous stream, color-configurable, for pipes
- `smoke_particles.tscn` — Soft gray puffs for broken/overloaded
- `celebration_particles.tscn` — Rainbow burst, stars/circles, for success
- `steam_particles.tscn` — White wisps rising, for overloaded

### 7. Audio System (`audio_manager.gd`)
Autoload singleton for sound management:
- Each component type has: place_sound, activate_sound, idle_loop, break_sound
- Parameter changes modulate pitch/speed of the idle_loop
- Wire connection: click/snap sound
- Simulation start: whoosh/power-up
- Success: cheerful jingle
- Use AudioStreamPlayer2D for positional audio (sounds come from components)
- Master volume, SFX volume, Music volume controls

### 8. Camera Improvements
- Smooth follow when simulation is running (track the action)
- Screen shake on big events (explosions, overloads)
- Zoom-to-fit button (frame all components)
- Smooth pinch-zoom with momentum

### 9. Background & Atmosphere
- Subtle animated grid background (workshop feel)
- Ambient workshop hum audio
- Lighting: components cast soft glow on nearby grid
- Optional: day/night cycle for vibes (stretch)

## Technical Notes
- Use Godot's Tween system for all animations (not AnimationPlayer for procedural stuff)
- GPUParticles2D for all particle effects (mobile performant)
- Object pool particle emitters — don't instantiate/free constantly
- Audio: use .ogg for music loops, .wav for short SFX
- All visual feedback should be toggleable (accessibility: reduce motion setting)
- Keep particle counts within mobile budget (max 500 total visible)

## Placeholder Assets
Generate or use placeholder assets:
- Simple geometric shapes for components (circles, rectangles, triangles)
- Solid colors matching the port type scheme (yellow/blue/green)
- Procedural sounds can be generated with Godot's AudioStreamGenerator or use sfxr-style generation
- For now, focus on making placeholders that clearly communicate function

## Output
Implement all systems above. Every component from Phase 1 should now have full visual and audio feedback. The game should feel "juicy" — placing, connecting, and running a simple machine should feel satisfying even with placeholder art.
