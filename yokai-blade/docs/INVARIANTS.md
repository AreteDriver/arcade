# YOKAI BLADE — System Invariants

> These are **non-negotiable contracts**. Violations are bugs, not features.

---

## Telegraph System Invariants

The telegraph system is the **central semantic truth layer**. It cannot lie.

### Visual Semantics (Absolute)

| Signal | Meaning | Notes |
|--------|---------|-------|
| White flash (1 frame) | Perfect deflect window | Must be frame-accurate |
| Red glow | Undodgeable hazard | Player must reposition |
| Blue shimmer | Illusion (never damages) | Safe to ignore |

### Audio Semantics (Absolute)

| Signal | Meaning | Notes |
|--------|---------|-------|
| Low bass cue | Arena-wide threat | Must cut through mix |
| High chime | Strike window opening | Opportunity signal |

### Telegraph Rules

1. **One semantic = one meaning, always**
   - No per-boss overrides
   - No context-dependent reinterpretation

2. **Bosses cannot override semantic meaning**
   - Visual deception is allowed (Tanuki)
   - Semantic deception is forbidden

3. **Comedy does not excuse dishonesty**
   - Absurd attacks still telegraph honestly
   - Funny animations don't hide real threat timing

---

## Combat System Invariants

### Timing

1. **Attack windows computed from data only**
   - No hard-coded attack timings
   - All timing lives in `AttackDefinition` ScriptableObjects

2. **Timing not tied to animation speed**
   - Gameplay timing is authoritative
   - Animations sync to gameplay, not vice versa

3. **Frame-rate independence**
   - Same attack yields same timing at 30/60/120 fps
   - Use fixed timestep or quantized frame clock

### Deflection

1. **Perfect deflect window is reliable**
   - No "sometimes" behavior
   - If white flash shows, deflect works

2. **Deflect always wins priority**
   - When overlapping with other inputs
   - No input should override defensive action

3. **Missed deflect produces explainable hit**
   - Player can understand why they failed
   - No mystery damage

### Input

1. **Buffered inputs replay consistently**
   - Across frame rates
   - Across hardware

2. **Input priority is deterministic**
   - Deflect > Strike > Dodge > Move

---

## Death Feedback Invariants

1. **Player can infer "what happened" within 1 second**
   - Attack name shown
   - Correct response icon shown
   - Brief freeze for recognition

2. **No tutorial text required**
   - Visual language is self-explanatory
   - Death is the teacher

3. **Fast retry loop**
   - Minimal friction between death and next attempt
   - No loading screens between retries

---

## Meter System Invariants

1. **No passive regeneration**
   - Meter gained only through mastery actions

2. **Meter misuse may trigger punishment states**
   - Power is granted through understanding
   - Not through accumulation

---

## Boss Design Invariants

1. **Every boss teaches one clear lesson**
   - Single core mechanic focus
   - Additional mechanics support, not distract

2. **Absurdity never removes danger**
   - Funny bosses are still lethal
   - Comedy is in the situation, not the threat level

3. **Patterns are readable, not random**
   - All attacks can be learned
   - No RNG in core threat windows

4. **Aggression without understanding is punished**
   - Button mashing fails
   - Observation and timing succeed

---

## Audio Invariants

1. **Telegraph cues always audible**
   - Sidechain against music/ambience during threat
   - Must pass laptop speaker test
   - Must pass stream compression test

2. **No comedy sounds**
   - Sound design is sincere
   - Humor comes from situation, not audio gags

---

## Code Quality Invariants

1. **No warnings treated as "known debt" unless documented**
   - All warnings either fixed or explicitly logged

2. **Tuning changes require notes**
   - No silent number tweaks
   - Document why values changed

3. **One major subsystem modified at a time**
   - Prevent thrash
   - Clear responsibility boundaries
