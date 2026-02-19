# YOKAI BLADE — Comedy-Safe Telegraph + Audio Rules (Production Constraints)

Senior-engineering mindset: these are invariants. Treat violations as bugs.

## A. Global Telegraph Invariants (Never Broken)

### Telegraph Syntax (absolute)
- **White flash (1 frame)** → Perfect deflect window
- **Red glow** → Undodgeable hazard (movement/positioning only)
- **Blue shimmer** → Illusion (never damages)
- **Low bass cue** → Arena-wide threat (always true)
- **High chime** → Strike window opening (always true)

**Rule:** Comedy may distort *appearance*, never *meaning*.

### Readability SLA (service-level agreement)
- If the player dies, they must be able to answer **“what killed me and what should I do instead”** within 1 second.
- If not, that attack is under-telegraphed or semantically inconsistent.

### Consistency over novelty
- New bosses introduce new *combinations* of known tells more than new tell types.
- If you add a new tell, it must be introduced in a safe context and reused globally afterward.

---

## B. Comedy-Safe Rules (No Tone Collapse)

### 1) No “Comedy Sounds”
Forbidden:
- Slide whistles, record scratches, cartoon boings, meme stingers
- Exaggerated vocal reactions that “wink” at the player

Allowed:
- Grounded foley
- Naturalistic ambience
- Understatement
- Silence

### 2) Silence is the punchline
- If the visuals are absurd, prefer *silence* or minimal ambience.
- Do not “help” the joke. The world never acknowledges the absurdity.

### 3) Telegraph audio is sacred
- Deflect chime, hazard bass, and strike-window tone are never parodied or swapped.
- These cues must stay recognizable under any mix and any boss.

### 4) Humor never reduces consequence
- Funny enemies remain lethal.
- Absurd animations still demand precision.
- Player laughter is permitted; player safety is not.

### 5) Comedy targets assumptions, not reflexes
- Deception bosses punish guessing, impatience, and overconfidence.
- Avoid “gotcha” timing changes. Deceive in *presentation*, not in timing.

### 6) Failure is treated with dignity
- No mocking fail jingles
- No comedic death stings
- Death feedback remains clean and instructive

---

## C. Audio Implementation Checklist

- Sidechain telegraph cues against music during high-threat moments.
- Ensure telegraph cues survive:
  - low volume play
  - phone speakers
  - stream compression
  - noisy rooms
- Provide accessibility toggles:
  - “Enhanced Telegraph Audio” (boost critical cues)
  - “Mono Mix” (prevent spatial-only tells)
  - “Subtitles for Telegraph Cues” (optional)

---

## D. Boss-Specific Tone Notes (Shirime / Tanuki / Oni)

### Shirime
- No music until player commits.
- Reveal is near-silent: discomfort is the humor.
- Deflect cue is the only “highlight.”

### Tanuki
- Music can be playful but never comedic.
- Allow deliberate “false starts” in rhythm, but keep telegraph cues truthful.

### Oni
- Minimal score. One drumbeat motif is enough.
- Every sound should feel heavy and final; no flourish.
