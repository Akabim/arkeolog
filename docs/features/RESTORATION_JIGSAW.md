# Restoration Jigsaw

## Status

Design specification — implementation not started.

---

## 1. Goal

The Restoration Jigsaw is a minigame where the player reconstructs
a collected artifact by placing irregularly shaped puzzle pieces onto
their corresponding positions in an artifact silhouette.

The system must support different artifact sizes and piece counts
without requiring a different implementation for each artifact.

---

## 2. Core Gameplay

The puzzle consists of:

- A central artifact silhouette.
- Multiple irregularly shaped puzzle pieces.
- Each puzzle piece corresponds to exactly one target position.
- Pieces spawn around the artifact in a radial/circular layout.

The puzzle is completed when every piece has been correctly placed
and locked.

There is no "Done" button.

---

## 3. Piece Assets

Each puzzle piece is provided as a separate art asset.

Pieces are irregularly shaped rather than simple rectangular blocks.

The visual shape of the piece is an art/content concern and should not
require the gameplay system to know the internal visual geometry.

---

## 4. Piece Rotation

Every puzzle piece has a canonical/correct rotation of:

0 degrees.

When the puzzle starts, each piece receives a random initial rotation
using 90-degree increments:

- 0°
- 90°
- 180°
- 270°

The player rotates the currently held piece in 90-degree steps.

Rotation can be performed using:

- `R`
- Right Mouse Button

R and Right Mouse Button perform the same rotation action.

The piece can be rotated while it is being dragged.

---

## 5. Piece Interaction

### Hover

When the mouse hovers over an interactable piece:

- The piece receives a subtle white outline.
- The outline is visual feedback only.
- Hover feedback must not alter puzzle state.

### Drag

The player uses Left Mouse Button to drag a piece.

Flow:

1. Press Left Mouse Button over an unlocked piece.
2. The piece becomes the active/held piece.
3. The piece follows the mouse while held.
4. The player may rotate it using R or Right Mouse Button.
5. Releasing Left Mouse Button attempts placement.

If no piece is being held and the player presses Right Mouse Button,
nothing happens.

---

## 6. Target Association

Every piece must have an unambiguous association with its correct
target.

The implementation must not rely on guessing which target is correct.

The exact technical representation of this relationship is an
architecture decision and is intentionally left open at the
specification level.

---

## 7. Placement Validation

A piece is considered correctly placed when:

1. The piece is sufficiently close to its corresponding target.
2. The piece rotation is correct.

Correct rotation is:

`0°`

Position validation is center/tolerance based rather than
pixel-perfect shape comparison.

The exact snap/placement tolerance is configurable and remains TBD
until playtesting.

Conceptually:

    distance(piece_center, target_center) <= snap_tolerance
    AND
    rotation == 0°

The system should avoid requiring pixel-perfect placement.

---

## 8. Correct Placement

When a piece is placed correctly:

1. The piece snaps to the exact target position.
2. The piece rotation becomes exactly 0°.
3. The piece becomes locked.
4. The piece can no longer be dragged.
5. The piece can no longer be rotated.
6. The piece is treated as completed.

The exact snap animation is considered polish and is not required for
core functionality.

---

## 9. Incorrect Placement

When a piece is released incorrectly:

1. The piece remains at the position where the player released it.
2. The piece does not snap back.
3. The puzzle remains playable.
4. Red visual feedback is triggered.
5. Screen shake feedback is triggered.

A small incorrect-placement sound may be added as polish.

The exact sound is not part of the core implementation requirement.

---

## 10. Completion

The puzzle is complete when all pieces have been correctly placed
and locked.

Conceptually:

    locked_piece_count == total_piece_count

When completion occurs, the restoration system must emit a completion
event/signal that can be consumed by other game systems.

The restoration system must not directly implement the photo mechanic.

---

## 11. Post-Restoration Flow

The intended high-level flow is:

    All Pieces Locked
          ↓
    Restoration Complete
          ↓
    Photo System
          ↓
    Journal / Progression
          ↓
    Next Level

The Photo System is currently TBD.

The Restoration Jigsaw should therefore expose a clean completion
event rather than directly depending on the future Photo System.

---

## 12. Piece Spawn Layout

Pieces spawn around the artifact silhouette using a radial/circular
layout.

The layout should support different numbers of pieces.

The exact radius and spacing are implementation/configuration
parameters.

The system should not hardcode a layout for one specific piece count.

For example:

- 3 pieces should produce a roughly triangular arrangement.
- 5 pieces should produce a roughly pentagonal arrangement.
- 10 pieces should produce a denser circular arrangement.

---

## 13. Spawn Animation

### Core

Pieces must appear in the radial layout.

### Optional Polish

Pieces may visually enter from outside the screen and settle into
their radial positions.

This animation must not affect gameplay state or placement logic.

---

## 14. Core Requirements

The first implementation must support:

- Central artifact silhouette.
- Irregular puzzle-piece assets.
- Separate asset per piece.
- Generic radial piece layout.
- Random initial rotation.
- 90-degree rotation.
- R rotation input.
- Right Mouse Button rotation input.
- Left Mouse Button dragging.
- Hover white outline.
- Correct target association.
- Center/tolerance placement validation.
- Correct snapping.
- Piece locking.
- Incorrect placement feedback.
- Screen shake feedback.
- Completion detection.
- Restoration completion event.

---

## 15. Deferred Polish

The following are explicitly deferred from the first core implementation:

- Spawn entrance animation.
- Hover lift animation.
- Magnetic pull animation.
- Advanced snap easing.
- Artifact glow.
- Golden particle effects.
- Detailed sound layering.
- Screen shake tuning.
- Advanced visual feedback.
- Photo mechanic.
- Journal presentation changes.

---

## 16. Out of Scope

The Restoration Jigsaw implementation must not:

- Implement the Photo System.
- Redesign the Journal system.
- Redesign level progression.
- Rebuild the entire inventory architecture.
- Implement the legacy Socket/StoneBlock restoration system.
- Remove unrelated legacy systems unless specifically required.
- Perform unrelated refactoring.

The legacy Socket/StoneBlock restoration system is considered
superseded by the Restoration Jigsaw design, but its removal should
be handled as a separate cleanup task unless the implementation
architecture requires otherwise.

---

## 17. Acceptance Criteria

### AC-01 — Piece Spawn

All available pieces appear around the artifact in a radial layout.

### AC-02 — Random Rotation

Each piece starts with a random rotation chosen from:

- 0°
- 90°
- 180°
- 270°

### AC-03 — Drag

The player can drag an unlocked piece using Left Mouse Button.

### AC-04 — Rotation

The player can rotate the held piece by 90° using either:

- R
- Right Mouse Button

### AC-05 — Hover Feedback

Hovering an unlocked piece produces a subtle white outline.

### AC-06 — Correct Placement

A piece within the configured position tolerance and at 0° rotation
snaps to its correct target.

### AC-07 — Incorrect Position

A piece outside the position tolerance does not snap.

### AC-08 — Incorrect Rotation

A piece with incorrect rotation does not snap.

### AC-09 — Incorrect Placement Feedback

Incorrect placement keeps the piece where it was released and triggers
red feedback and screen shake.

### AC-10 — Locking

A correctly placed piece becomes locked and cannot be moved or rotated.

### AC-11 — Completion

The puzzle reports completion when all pieces are locked.

### AC-12 — External Completion Event

The Restoration Jigsaw exposes a completion signal/event without
directly implementing the Photo System.

### AC-13 — No-op Right Click

Right Mouse Button without an actively held piece produces no
rotation and no gameplay side effect.

### AC-14 — Generic Piece Count

The system supports different numbers of puzzle pieces without
requiring separate puzzle logic for each count.

---

## 18. Open Questions / TBD

The following are intentionally unresolved:

- Exact snap tolerance value.
- Exact radial layout radius.
- Exact spacing rules for different piece counts.
- Exact representation of piece-to-target association.
- Exact Godot scene/node architecture.
- Exact asset import/setup workflow.
- Exact hover outline implementation.
- Exact screen shake intensity/duration.
- Photo System design.
- Final audio assets.