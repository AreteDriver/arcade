# Python Version - Porting Complete

**Status:** ✅ COMPLETE - Python version (EVE_Rebellion) deleted 2026-01-30

All features from the Python/Pygame version have been ported to Rust/Bevy. The Python repository has been deleted after harvesting intellectual resources.

---

## Harvested Resources

The following materials were preserved in `docs/` and `config/`:

### Design Documentation (docs/)
- `DESIGN_PHILOSOPHY.md` - Game design fusion methodology (Devil Blade + EVE)
- `CONTROLLER_DESIGN.md` - Analog control philosophy and mappings
- `CINEMATIC_DESIGN.md` - Narrative pacing and scene composition
- `ACE_CHARACTER_MOMENTS.md` - Character writing guidelines
- `DEVIL_BLADE_INTEGRATION.md` - Salt Miner system integration guide

### Reference Materials (docs/harvested_from_python/)
- `procedural_audio_reference.py` - Sound synthesis algorithms (numpy/scipy)
- `lessons-learned-2026-01-18.md` - CI/CD operational knowledge

### Game Data (config/)
- `enemies_expansion.json` - Pirate/SoE factions, capital ships
- `stages_expansion.json` - Expansion stages 6-8 with narrative

---

## Ported Features Summary

| Feature | Status | Rust Location |
|---------|--------|---------------|
| Salt Miner scoring | ✅ | `systems/scoring.rs` |
| Rarity system | ✅ | `entities/collectible.rs` |
| Damage visuals | ✅ | `systems/effects.rs` |
| Pickup effects | ✅ | `systems/effects.rs` |
| Buff warnings | ✅ | `ui/hud.rs` |
| Active buff visuals | ✅ | `systems/effects.rs` |
| Background ships | ✅ | `ui/backgrounds.rs` |
| Controller profiles | ✅ | `systems/joystick.rs` |
| Steam Deck support | ✅ | `systems/joystick.rs` |
| Campaign system | ✅ | `campaigns/` |
| Audio system | ✅ | `systems/audio.rs`, `systems/music.rs` |

---

## Archive Note

The Python version served as the prototype for:
- Core gameplay mechanics
- Visual effect design
- Audio synthesis approach
- Game balance tuning

The Rust version supersedes it with:
- Better performance (60fps on modest hardware)
- WASM support (web builds)
- Multiple campaigns (Elder Fleet, Caldari/Gallente, Endless)
- Modern ECS architecture (Bevy 0.15)

*Last Updated: 2026-01-30*
