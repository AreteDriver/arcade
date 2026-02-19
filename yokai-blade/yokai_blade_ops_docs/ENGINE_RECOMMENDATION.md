# Engine Recommendation (YOKAI BLADE)

## Recommendation: Unity LTS + URP (default)
For this project’s needs (tight combat timing, data-driven bosses, rapid graybox iteration, shipping a vertical slice fast), Unity LTS is the best “time-to-playable” choice.

### Why Unity LTS
- Fast iteration loop (play mode, prefab workflow, hot iteration)
- Mature C# ecosystem for data-driven gameplay (ScriptableObjects, editor tooling)
- Strong controller + input stack options
- Large pool of reference implementations for combat timing and state machines
- Easy to onboard contractors later (common toolchain)

### Why URP
- Good baseline rendering without overengineering
- Easy shader/VFX prototyping for telegraph cues (white flash/red glow/blue shimmer)
- Scales from graybox to production without switching pipelines

### Audio Approach
- Start with Unity audio routing + simple mixer buses (Telegraph/SFX/Music/Ambience)
- If/when you need advanced mixing and tooling, migrate to FMOD (optional)

---

## Alternative (only if you prefer open-source workflow): Godot 4
Godot 4 can work well for a smaller team, but you’ll spend more time building tools Unity gives you out-of-box (editor pipelines, asset workflows, third-party integrations). Use it only if you strongly want OSS + lightweight footprint.

---

## Lock Decisions (fill in)
- Engine: Unity LTS (version: ________)
- Render: URP
- Input: Unity Input System
- Audio: Unity Mixer (FMOD later optional)
- Target FPS: 60 (tuning baseline)
- Timing: Fixed timestep / quantized clock (documented)
