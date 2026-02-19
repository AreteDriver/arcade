# Version Control Discipline (Non-Optional)

## Branching
- main: always playable
- feature/*: small scoped changes only

## Commit Policy
- One Claude session = one primary change set = one commit
- Conventional commits:
  - feat:, fix:, chore:, docs:, test:, refactor:
- No mega-commits
- Every timing change must update:
  - attack_tuning.csv
  - TUNING_CHANGELOG.md

## Code Review Checklist (even solo)
- Does this change violate telegraph semantics?
- Did any timing drift without explanation?
- Does audio remain readable?
- Does humor remain unacknowledged by the world?
