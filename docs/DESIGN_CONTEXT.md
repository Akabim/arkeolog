# DESIGN CONTEXT — ARKEOLOG

## Game / Tone
- Cozy archaeology adventure.
- Focus: exploration, excavation, restoration, documentation, journal, progression.

## Restoration Jigsaw — Confirmed
- Player restores one artifact from multiple separate irregular pieces.
- Pieces spawn radially around the artifact silhouette.
- Restoration intro presentation: pieces are presented around the silhouette and settle into their radial staging positions with a short "placed on the table" style animation before player control begins. This is a presentation/polish layer, not a puzzle-rule requirement.
- LMB = drag.
- R = rotate 90°.
- RMB = rotate 90°.
- Rotation works while dragging.
- Initial rotation: random 0/90/180/270°.
- Correct rotation = 0°.
- Hover = subtle white outline.
- Correct placement = snap, lock, target completed.
- Incorrect placement = stay at release position + red feedback + UI shake.
- Locked pieces cannot be manipulated.
- No manual Done button.
- Puzzle completes when all pieces are correctly placed.

## Artifact Progression — Confirmed
1 artifact:
Restoration → celebration → Photo Mode → shutter → Polaroid → Journal → Journal auto-closes → Overworld.

Multiple artifacts:
- Each artifact gets its own Restoration → Photo → Journal cycle.
- After returning to Overworld, contextual dialogue can indicate remaining artifacts.
- Example: "Masih ada satu artefak lagi yang harus kita pulihkan."
- When all required artifacts are complete: final Journal → Site/Level Complete → Next Place/Level.

## Altar — Confirmed Direction
- Altar is visible and interactable from the beginning.
- Incomplete fragments → short contextual dialogue.
- Altar may be interacted with repeatedly while required fragments are incomplete.
- Incomplete altar dialogue reflects current fragment progress and may use small variations so repeated interactions do not always repeat the exact same line.
- Complete fragments → E starts Restoration directly; no additional pre-restoration dialogue.
- Dialogic 2 is the dialogue system.
- V1 transition into Restoration = normal fade.
- Player cannot freely leave Restoration before completion.

## Photo Mode — Confirmed Direction
- Player returns to overworld context near the artifact/altar.
- Player cannot move during photo mode.
- Mouse wheel = zoom.
- Space = shutter.

## Journal / Polaroid — Confirmed Direction
- After shutter, Polaroid appears.
- Polaroid animates into Journal.
- Journal shows the restored artifact entry.
- Journal auto-closes afterward.
- Final artifact may use an extended completion presentation.

## Current Content
- The recurring artifact/entity concept changed from the earlier Ganesha plan to a fictional cat deity/entity.
- Level 1 first restoration concept: a cat-deity statue in a Hindu-inspired sculptural style.
- The artist is creating the new artifact artwork.
- New Jigsaw assets do NOT exist yet.
- Legacy Prasasti/Batu assets are NOT the new Jigsaw content.

## Cross-Level Artifact Direction — Confirmed Direction
- The game may feature one recurring cat-deity/entity represented through different artifact forms across levels.
- Each level's artifact form can differ substantially while remaining part of the same recurring entity concept.
- Level 2 example currently being considered: an Egyptian-style vessel/kendi associated with the recurring cat-deity/entity.
- Exact level-by-level artifact forms beyond Level 1 remain TBD until finalized.

## Art Specification
Per artifact:
- silhouette.png
- reference.png
- piece_01.png ... piece_N.png
- PNG RGBA transparency.
- Artist may keep each piece on a 1000x1000 canvas with transparent unused space.
- Pieces should visually read as irregular archaeological fragments.
- Level 1 guideline: 3–4 pieces.

## TBD
- Exact Level 1 cat-deity piece division.
- Exact final artifact visuals.
- Exact artifact forms for future levels.
- Exact target offsets.
- Snap tolerance final tuning.
- Photo presentation polish.
- Final Journal presentation polish.
- Final Site Complete presentation.

## OUT OF SCOPE FOR NOW
- Do not reuse legacy Prasasti/Batu puzzle assets.
- Do not redesign the existing Jigsaw Core.
- Do not lock final target offsets before final artwork exists.

## Next Integration Flow — Confirmed Direction

### Artifact Cycle
Each artifact follows:
Restoration → Completion Celebration → Photo Mode → Shutter → Polaroid → Journal → Journal Auto-Close → Overworld.

### Altar
- Altar is visible from the beginning.
- Player can interact with the altar from the beginning.
- Missing required fragments → contextual Dialogic 2 dialogue.
- Player can re-interact while incomplete; dialogue should reflect current progress and may vary slightly.
- Complete required fragments → contextual prompt to start Restoration.
- Start interaction with `E`.
- V1 transition into Restoration uses a normal fade.
- Player cannot freely exit Restoration before completion.

### Restoration Intro
- After the fade into Restoration, pieces are staged around the artifact silhouette in a radial layout.
- The intended intro presentation is that pieces appear/settle around the silhouette as if being placed on a work surface, rather than flying in from the screen edges.
- Player input begins only after the intro presentation completes.
- The exact animation timing and visual polish remain deferred.

### Restoration Completion
- Restoration Core emits `restoration_completed`.
- Restoration Core does NOT own Photo, Journal, or progression.
- A higher-level flow/gameplay layer decides what happens after completion.
- Artifact celebration happens before Photo Mode.

### Photo Mode
- Player returns to overworld near the altar/artifact context.
- Player movement is disabled during Photo Mode.
- Mouse wheel controls zoom.
- Space triggers the shutter.

### Photo → Journal
- Shutter triggers a Polaroid presentation.
- Polaroid animates into the Journal.
- Journal displays the artifact entry.
- Journal closes automatically afterward.
- Player returns to the overworld.

### Multiple Artifacts
- One artifact = one complete Restoration → Photo → Journal cycle.
- After returning to the overworld, contextual dialogue may indicate remaining artifacts.
- Example: "Masih ada satu artefak lagi yang harus kita pulihkan."
- After all required artifacts are completed:
  - final Journal presentation
  - Site/Level Complete
  - Next Place / Next Level

### Implementation Sequence
Do NOT implement the entire flow as one task.

1. Task A — Altar → Restoration entry
2. Task B — Restoration completion → Photo Mode
3. Task C — Photo → Journal → progression

Each task must be integrated and verified before starting the next.