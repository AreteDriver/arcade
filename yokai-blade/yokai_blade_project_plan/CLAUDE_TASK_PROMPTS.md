# YOKAI BLADE — Claude Code Task Prompts (Copy/Paste)

Use one prompt per session. Do not run multiple major prompts without a clean commit.

---

## Prompt 01 — Initialize Repo + Unity Project Skeleton
Create a Unity LTS project with the exact folder layout from docs. Add Boot scene that loads an empty graybox room. Add .editorconfig and basic CI placeholder. Commit as `chore: init project skeleton`.

---

## Prompt 02 — Implement Telegraph Semantics + Catalog (Blocker)
Implement TelegraphSemantic enum, TelegraphCatalog asset (semantic → vfxId/sfxId), TelegraphSystem event bus, and debug overlay that displays last semantic emitted. Add unit tests ensuring mapping cannot vary by boss. Commit as `feat: telegraph semantics v1`.

---

## Prompt 03 — Input System + Buffering Rules
Implement input actions (Move/Dodge/Deflect/Strike) with buffering and priority: Deflect > Dodge > Strike. Create a test scene validating buffered inputs replay consistently at different frame rates. Commit as `feat: input v1`.

---

## Prompt 04 — AttackDefinition Data Pipeline
Create AttackDefinition ScriptableObject with timing fields, semantic, damage, and death feedback. Add data validation at load. Author 3 sample attacks as assets. Commit as `feat: attack definition pipeline`.

---

## Prompt 05 — AttackRunner Timeline + Telegraph Emit
Implement AttackRunner that executes Startup→Active→Recovery based on AttackDefinition, emits telegraph at startup, and triggers spawn events for hit volumes/projectiles. Add timing regression tests. Commit as `feat: attack runner v1`.

---

## Prompt 06 — Deflect System + Reward Hooks
Implement DeflectSystem with perfect/standard windows derived from AttackDefinition timeline. Add reward hooks (meter gain stub, stagger callback). Add practice dummy harness for deflect testing. Commit as `feat: deflect system v1`.

---

## Prompt 07 — Death Feedback System
Implement FreezeManager + DeathFeedback UI panel that shows attack name and response icon. Ensure fast retry. Add tests that death feedback payload is always populated. Commit as `feat: death feedback v1`.

---

## Prompt 08 — Shirime Encounter (First Playable)
Create Shirime_Arena scene. Implement Shirime boss brain with Bow→Wait→EyeBeam flow and Punish state if attacked early. Victory on perfect deflect of EyeBeam. No music until commitment. Commit as `feat: shirime encounter v1`.

---

## Prompt 09 — Audio Routing + Telegraph Bus Sidechain
Implement AudioRouter with buses and sidechain behavior so telegraph cues always cut through. Add a quick audibility test mode. Commit as `feat: audio routing v1`.

---

## Prompt 10 — Tanuki Encounter
Create Tanuki arena + Trickster Road transition. Implement Tanuki deception using visuals only; semantics remain honest. Add counter punishing blind swings. Commit as `feat: tanuki encounter v1`.

---

## Prompt 11 — Oni Encounter
Create Oni arena. Implement 3-phase Oni state machine with escalating pressure and no gimmicks. Commit as `feat: oni encounter v1`.

---

## Prompt 12 — QA Pass + Capture Build
Run full test suite. Fix regressions. Produce a capture-ready build. Add a short “how to play” page that only states controls and covenant. Commit as `chore: vertical slice qa + build`.
