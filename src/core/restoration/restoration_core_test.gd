class_name RestorationCoreTest
extends RefCounted

static func run_all_tests() -> Dictionary:
	var results := {
		"total": 0,
		"passed": 0,
		"failed": 0,
		"errors": []
	}
	
	test_radial_calculation(results)
	test_target_calculation(results)
	test_rotation_steps(results)
	test_piece_movement_and_locking(results)
	test_placement_validation_and_completion(results)
	
	return results

static func _assert(condition: bool, test_name: String, results: Dictionary) -> void:
	results["total"] += 1
	if condition:
		results["passed"] += 1
	else:
		results["failed"] += 1
		results["errors"].append("FAILED: " + test_name)

static func test_radial_calculation(results: Dictionary) -> void:
	var center := Vector2(960, 540)
	var radius := 200.0
	# Index 0 with 4 pieces -> angle = -PI/2 (top) -> (960, 340)
	var pos0 := RestorationController.calculate_radial_position(center, 0, 4, radius)
	_assert(pos0.is_equal_approx(Vector2(960, 340)), "Radial pos piece 0 at top", results)
	
	# Index 1 with 4 pieces -> angle = 0 (right) -> (1160, 540)
	var pos1 := RestorationController.calculate_radial_position(center, 1, 4, radius)
	_assert(pos1.is_equal_approx(Vector2(1160, 540)), "Radial pos piece 1 at right", results)

static func test_target_calculation(results: Dictionary) -> void:
	var center := Vector2(500, 500)
	var offset := Vector2(25, -50)
	var target := RestorationController.calculate_target_position(center, offset)
	_assert(target == Vector2(525, 450), "Target position equals center + offset", results)

static func test_rotation_steps(results: Dictionary) -> void:
	_assert(RestorationController.step_to_degrees(0) == 0.0, "Step 0 == 0 deg", results)
	_assert(RestorationController.step_to_degrees(1) == 90.0, "Step 1 == 90 deg", results)
	_assert(RestorationController.step_to_degrees(2) == 180.0, "Step 2 == 180 deg", results)
	_assert(RestorationController.step_to_degrees(3) == 270.0, "Step 3 == 270 deg", results)
	_assert(RestorationController.step_to_degrees(4) == 0.0, "Step 4 wraps to 0 deg", results)

static func test_piece_movement_and_locking(results: Dictionary) -> void:
	var puzzle := RestorationPuzzleData.new()
	puzzle.artifact_id = "test_artifact"
	puzzle.snap_tolerance = 30.0
	puzzle.radial_radius = 200.0
	
	var piece1 := JigsawPieceData.new()
	piece1.piece_id = "p1"
	piece1.target_offset = Vector2(-20, 0)
	
	puzzle.pieces.append(piece1)
	
	var controller := RestorationController.new()
	controller.initialize_puzzle(puzzle, Vector2(500, 500), false) # No random rot (step 0)
	
	_assert(controller.get_total_count() == 1, "Total count is 1", results)
	_assert(not controller.is_piece_locked("p1"), "Piece not locked initially", results)
	
	# Move piece
	controller.set_piece_position("p1", Vector2(100, 100))
	_assert(controller.get_piece_state("p1").current_position == Vector2(100, 100), "Position updated", results)
	
	# Rotate piece
	controller.rotate_piece("p1", true)
	_assert(controller.get_piece_state("p1").rotation_step == 1, "Rotated clockwise to step 1", results)
	
	# Invalid placement because rotation != 0
	controller.set_piece_position("p1", Vector2(480, 500)) # target is 480, 500
	var success := controller.release_piece("p1")
	_assert(not success, "Placement invalid due to rotation", results)
	_assert(not controller.is_piece_locked("p1"), "Piece remains unlocked", results)
	_assert(controller.get_piece_state("p1").current_position == Vector2(480, 500), "Piece stays at drop position", results)

static func test_placement_validation_and_completion(results: Dictionary) -> void:
	var puzzle := RestorationPuzzleData.new()
	puzzle.artifact_id = "artifact_complete"
	puzzle.snap_tolerance = 30.0
	puzzle.radial_radius = 200.0
	
	var p1 := JigsawPieceData.new()
	p1.piece_id = "p1"
	p1.target_offset = Vector2(0, 0)
	
	var p2 := JigsawPieceData.new()
	p2.piece_id = "p2"
	p2.target_offset = Vector2(50, 50)
	
	puzzle.pieces.append_array([p1, p2])
	
	var controller := RestorationController.new()
	controller.initialize_puzzle(puzzle, Vector2(400, 400), false)
	
	# Place p1 correctly within snap tolerance
	controller.set_piece_position("p1", Vector2(410, 405)) # dist ~ 11.18 <= 30.0
	var snap1 := controller.release_piece("p1")
	_assert(snap1, "p1 placement valid and snapped", results)
	_assert(controller.is_piece_locked("p1"), "p1 is locked", results)
	_assert(controller.get_piece_state("p1").current_position == Vector2(400, 400), "p1 snapped to exact target", results)
	_assert(controller.get_locked_count() == 1, "Locked count is 1", results)
	_assert(not controller.is_complete(), "Puzzle not yet complete", results)
	
	# Attempt to move locked piece
	var move_locked := controller.set_piece_position("p1", Vector2(0, 0))
	_assert(not move_locked, "Cannot move locked piece", results)
	
	# Place p2 correctly
	controller.set_piece_position("p2", Vector2(450, 450)) # target is 450, 450
	var snap2 := controller.release_piece("p2")
	_assert(snap2, "p2 placement valid", results)
	_assert(controller.get_locked_count() == 2, "Locked count is 2", results)
	_assert(controller.is_complete(), "Puzzle is complete", results)
