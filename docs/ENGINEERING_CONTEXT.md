# ENGINEERING CONTEXT — ARKEOLOG

## Project
- Engine: Godot 4.7
- Repo: https://github.com/Akabim/arkeolog
- Main branch is synchronized with origin.
- Latest known checkpoint commit: 0b4a25b
- Working tree was clean after push.

## Restoration Implementation
### Core
- src/core/resources/jigsaw_piece_data.gd
- src/core/resources/restoration_puzzle_data.gd
- src/core/restoration/jigsaw_piece_state.gd
- src/core/restoration/restoration_controller.gd

### Input
- src/core/restoration/restoration_input_handler.gd

### UI
- src/ui/restoration/jigsaw_piece_view.gd
- src/ui/restoration/jigsaw_piece_view.tscn
- src/ui/restoration/restoration_overlay.gd
- src/ui/restoration/restoration_overlay.tscn

### Tests
- Core: 24/24 PASS
- Input: 38/38 PASS
- UI: 14/14 PASS
- Total: 76/76 PASS

## Verified Runtime
- Main project/sandbox opens.
- No parser errors.
- No runtime errors observed in Output.
- Restoration standalone/F6 flow has been tested.

## Architecture Boundaries
- RestorationController owns puzzle truth, validation, snapping, locking, completion.
- RestorationInputHandler translates player input to Core API.
- RestorationOverlay/JigsawPieceView present Core state.
- QA verifies implementation.
- Restoration Core must NOT own Photo, Journal, or level progression.
- Prefer existing project systems over duplicates.
- Do not modify working Jigsaw Core/Input/UI without concrete integration need.

## Existing Systems
- Global state machine currently has existing states including OVERWORLD, EXCAVATION, JOURNAL.
- RESTORATION state has been identified as required for integration but is NOT yet part of the final altar flow.
- InventoryManager exists and tracks collected fragments / assembled artifacts.
- Dialogic 2 is installed and enabled.
- Legacy Socket/StoneBlock systems still exist; new Restoration Jigsaw should not depend on them.

## Current Integration Status
NOT IMPLEMENTED:
- Overworld Altar entity/scene
- Altar → Restoration entry
- RESTORATION state integration
- Photo Mode
- Polaroid → Journal flow
- Final level progression

A prior architecture inspection proposed an Altar integration, but implementation was NOT approved and should NOT be assumed complete.

## Current Content Blocker
- New Level 1 Ganesha artwork is being created by the artist.
- Do not build final RestorationPuzzleData from legacy Prasasti/Batu assets.
- Final target_offset values must come from the new artwork/reference.

## Agent Boundaries
- restoration-core: puzzle logic/data/state
- restoration-input: mouse/keyboard translation
- restoration-ui: presentation
- restoration-qa: verification

## Working Rule
Before changing code:
1. Read this file.
2. Read docs/DESIGN_CONTEXT.md.
3. Inspect git status and recent commits.
4. Inspect the actual repository.
5. Reuse existing systems.
6. Keep tasks bounded.
7. Verify changes with tests.

## Current Next Step
Wait for the new Ganesha artifact assets, then:
1. Inspect asset format.
2. Create real puzzle data.
3. Test playable Ganesha restoration.
4. QA.
5. Then implement Altar → Restoration integration.
