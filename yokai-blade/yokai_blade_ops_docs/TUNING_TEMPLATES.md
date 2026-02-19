# Tuning Source-of-Truth

## Files to Create
- `Assets/Game/Tuning/attack_tuning.csv` (authoritative numeric values)
- `docs/TUNING_CHANGELOG.md` (human readable rationale)

## attack_tuning.csv (template)

Columns:
- attack_id
- startup_ms
- active_ms
- recovery_ms
- perfect_deflect_ms
- standard_deflect_ms
- damage
- notes

Example rows:
```
attack_id,startup_ms,active_ms,recovery_ms,perfect_deflect_ms,standard_deflect_ms,damage,notes
Shirime_EyeBeam,900,120,800,33,120,20,"Baseline: readable; instant-win on perfect deflect"
Tanuki_CounterStance,700,150,900,40,140,18,"Punishes blind swings; semantics unchanged"
Oni_Slam,800,180,900,33,120,28,"Heavy telegraph; teaches respect"
```

## TUNING_CHANGELOG.md (template)
Every timing change must include:
- what changed
- why
- what improved
- what risk it introduces

Example:
- 2025-12-28 — Shirime_EyeBeam startup 800→900ms  
  Why: new testers misread beam onset.  
  Improvement: clearer “wait then deflect” lesson.  
  Risk: lowers pressure; watch for boredom.
