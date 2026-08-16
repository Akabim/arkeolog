# DESIGN CONTEXT — ARKEOLOG

## Game / Tone
- Cozy archaeology adventure.
- Focus: exploration, excavation, restoration, documentation, journal, progression.

## Restoration Jigsaw — Confirmed
- Player restores one artifact from multiple separate irregular pieces.
- Pieces spawn radially around the artifact silhouette.
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
- Complete fragments → E starts Restoration.
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
- Level 1 first restoration concept: Ganesha statue.
- Artist is creating the new Ganesha artwork.
- New Jigsaw assets do NOT exist yet.
- Legacy Prasasti/Batu assets are NOT the new Jigsaw content.

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
- Exact Ganesha piece division.
- Exact final visuals.
- Exact target offsets.
- Snap tolerance final tuning.
- Photo presentation polish.
- Final Journal presentation polish.
- Final Site Complete presentation.

## OUT OF SCOPE FOR NOW
- Do not reuse legacy Prasasti/Batu puzzle assets.
- Do not redesign the existing Jigsaw Core.
- Do not lock final target offsets before final artwork exists.
