class_name RestorationInputTest
extends RefCounted

const RestorationPuzzleData = preload("res://src/core/resources/restoration_puzzle_data.gd")
const JigsawPieceData = preload("res://src/core/resources/jigsaw_piece_data.gd")
const RestorationController = preload("res://src/core/restoration/restoration_controller.gd")
const JigsawPieceState = preload("res://src/core/restoration/jigsaw_piece_state.gd")
const RestorationInputHandler = preload("res://src/core/restoration/restoration_input_handler.gd")

static func run_all_tests() -> Dictionary:
	var results := {
		"total": 0,
		"passed": 0,
		"failed": 0,
		"errors": []
	}
	
	test_hit_testing(results)
	test_hit_testing_non_square_rotated(results)
	test_lmb_drag_and_offset(results)
	test_lmb_release(results)
	test_rmb_and_r_rotation(results)
	test_rotation_with_no_held_piece(results)
	test_locked_piece_immunity(results)
	test_hover_detection(results)
	test_cancel_drag(results)
	
	return results

static func _assert(condition: bool, test_name: String, results: Dictionary) -> void:
	results["total"] += 1
	if condition:
		results["passed"] += 1
	else:
		results["failed"] += 1
		results["errors"].append("FAILED: " + test_name)

static func _create_test_puzzle() -> RestorationPuzzleData:
	var puzzle := RestorationPuzzleData.new()
	puzzle.artifact_id = "test_artifact"
	puzzle.snap_tolerance = 40.0
	puzzle.radial_radius = 200.0
	
	var p1 := JigsawPieceData.new()
	p1.piece_id = "p1"
	p1.target_offset = Vector2(-50, 0)
	
	var p2 := JigsawPieceData.new()
	p2.piece_id = "p2"
	p2.target_offset = Vector2(50, 0)
	
	puzzle.pieces.append_array([p1, p2])
	return puzzle

static func test_hit_testing(results: Dictionary) -> void:
	var controller := RestorationController.new()
	controller.initialize_puzzle(_create_test_puzzle(), Vector2(500, 500), false)
	controller.set_piece_position("p1", Vector2(100, 100))
	controller.set_piece_position("p2", Vector2(300, 300))
	
	var handler := RestorationInputHandler.new(controller, {
		"p1": Vector2(60, 60),
		"p2": Vector2(60, 60)
	})
	
	_assert(handler.hit_test_piece(Vector2(100, 100)) == "p1", "Hit center of p1", results)
	_assert(handler.hit_test_piece(Vector2(125, 125)) == "p1", "Hit inside p1 bound", results)
	_assert(handler.hit_test_piece(Vector2(140, 140)) == "", "Miss outside p1 bound", results)
	_assert(handler.hit_test_piece(Vector2(300, 300)) == "p2", "Hit center of p2", results)

static func test_hit_testing_non_square_rotated(results: Dictionary) -> void:
	var controller := RestorationController.new()
	controller.initialize_puzzle(_create_test_puzzle(), Vector2(500, 500), false)
	controller.set_piece_position("p1", Vector2(400, 400)) # Center
	
	# p1 size: 200 width x 60 height
	var handler := RestorationInputHandler.new(controller, {
		"p1": Vector2(200, 60)
	})
	
	# Step 0: 0° -> extent X: [300, 500], Y: [370, 430]
	_assert(handler.hit_test_piece(Vector2(480, 400)) == "p1", "0 deg: horizontal wing hit", results)
	_assert(handler.hit_test_piece(Vector2(400, 480)) == "", "0 deg: vertical wing miss", results)
	
	# Step 1: 90° -> extent X: [370, 430], Y: [300, 500]
	controller.rotate_piece("p1", true)
	_assert(handler.hit_test_piece(Vector2(480, 400)) == "", "90 deg: old horizontal wing miss", results)
	_assert(handler.hit_test_piece(Vector2(400, 480)) == "p1", "90 deg: new vertical wing hit", results)
	
	# Step 2: 180° -> extent X: [300, 500], Y: [370, 430]
	controller.rotate_piece("p1", true)
	_assert(handler.hit_test_piece(Vector2(480, 400)) == "p1", "180 deg: horizontal wing hit", results)
	_assert(handler.hit_test_piece(Vector2(400, 480)) == "", "180 deg: vertical wing miss", results)
	
	# Step 3: 270° -> extent X: [370, 430], Y: [300, 500]
	controller.rotate_piece("p1", true)
	_assert(handler.hit_test_piece(Vector2(480, 400)) == "", "270 deg: horizontal wing miss", results)
	_assert(handler.hit_test_piece(Vector2(400, 480)) == "p1", "270 deg: vertical wing hit", results)

static func test_lmb_drag_and_offset(results: Dictionary) -> void:
	var controller := RestorationController.new()
	controller.initialize_puzzle(_create_test_puzzle(), Vector2(500, 500), false)
	controller.set_piece_position("p1", Vector2(200, 200))
	
	var handler := RestorationInputHandler.new(controller, { "p1": Vector2(100, 100) })
	
	# Click at (220, 210) -> drag_offset should be (200 - 220, 200 - 210) = (-20, -10)
	var mb_down := InputEventMouseButton.new()
	mb_down.button_index = MOUSE_BUTTON_LEFT
	mb_down.pressed = true
	
	var handled := handler.handle_gui_input(mb_down, Vector2(220, 210))
	_assert(handled, "LMB down handled on piece", results)
	_assert(handler.held_piece_id == "p1", "p1 is now held", results)
	_assert(handler.drag_offset == Vector2(-20, -10), "Drag offset computed accurately", results)
	
	# Move mouse to (320, 310) -> new piece position should be (320 - 20, 310 - 10) = (300, 300)
	var mm := InputEventMouseMotion.new()
	var motion_handled := handler.handle_gui_input(mm, Vector2(320, 310))
	_assert(motion_handled, "Mouse motion handled while dragging", results)
	_assert(controller.get_piece_state("p1").current_position == Vector2(300, 300), "Piece moved preserving offset", results)

static func test_lmb_release(results: Dictionary) -> void:
	var controller := RestorationController.new()
	controller.initialize_puzzle(_create_test_puzzle(), Vector2(500, 500), false)
	controller.set_piece_position("p1", Vector2(200, 200))
	
	var handler := RestorationInputHandler.new(controller, { "p1": Vector2(100, 100) })
	
	var mb_down := InputEventMouseButton.new()
	mb_down.button_index = MOUSE_BUTTON_LEFT
	mb_down.pressed = true
	handler.handle_gui_input(mb_down, Vector2(200, 200))
	
	var mb_up := InputEventMouseButton.new()
	mb_up.button_index = MOUSE_BUTTON_LEFT
	mb_up.pressed = false
	
	var released := handler.handle_gui_input(mb_up, Vector2(200, 200))
	_assert(released, "LMB up handled", results)
	_assert(handler.held_piece_id == "", "Held piece cleared after release", results)

static func test_rmb_and_r_rotation(results: Dictionary) -> void:
	var controller := RestorationController.new()
	controller.initialize_puzzle(_create_test_puzzle(), Vector2(500, 500), false)
	controller.set_piece_position("p1", Vector2(200, 200))
	
	var handler := RestorationInputHandler.new(controller, { "p1": Vector2(100, 100) })
	
	# Pick up p1
	var mb_down := InputEventMouseButton.new()
	mb_down.button_index = MOUSE_BUTTON_LEFT
	mb_down.pressed = true
	handler.handle_gui_input(mb_down, Vector2(200, 200))
	
	_assert(controller.get_piece_state("p1").rotation_step == 0, "Initial rot step is 0", results)
	
	# Rotate via RMB
	var mb_right := InputEventMouseButton.new()
	mb_right.button_index = MOUSE_BUTTON_RIGHT
	mb_right.pressed = true
	var rmb_handled := handler.handle_gui_input(mb_right, Vector2(200, 200))
	_assert(rmb_handled, "RMB handled when holding piece", results)
	_assert(controller.get_piece_state("p1").rotation_step == 1, "RMB rotated to step 1 (90 deg CW)", results)
	
	# Rotate via R key
	var key_r := InputEventKey.new()
	key_r.keycode = KEY_R
	key_r.pressed = true
	key_r.echo = false
	var key_handled := handler.handle_key_input(key_r)
	_assert(key_handled, "R key handled when holding piece", results)
	_assert(controller.get_piece_state("p1").rotation_step == 2, "R key rotated to step 2 (180 deg CW)", results)

static func test_rotation_with_no_held_piece(results: Dictionary) -> void:
	var controller := RestorationController.new()
	controller.initialize_puzzle(_create_test_puzzle(), Vector2(500, 500), false)
	
	var handler := RestorationInputHandler.new(controller)
	_assert(handler.held_piece_id == "", "No piece held", results)
	
	# RMB with no held piece
	var mb_right := InputEventMouseButton.new()
	mb_right.button_index = MOUSE_BUTTON_RIGHT
	mb_right.pressed = true
	_assert(not handler.handle_gui_input(mb_right, Vector2(100, 100)), "RMB with no held piece is no-op", results)
	
	# R key with no held piece
	var key_r := InputEventKey.new()
	key_r.keycode = KEY_R
	key_r.pressed = true
	key_r.echo = false
	_assert(not handler.handle_key_input(key_r), "R key with no held piece is no-op", results)

static func test_locked_piece_immunity(results: Dictionary) -> void:
	var controller := RestorationController.new()
	controller.initialize_puzzle(_create_test_puzzle(), Vector2(500, 500), false)
	
	# Target for p1 is (500 + -50, 500) = (450, 500). Place it accurately so it locks
	controller.set_piece_position("p1", Vector2(450, 500))
	controller.release_piece("p1")
	_assert(controller.is_piece_locked("p1"), "p1 is locked", results)
	
	var handler := RestorationInputHandler.new(controller, { "p1": Vector2(100, 100) })
	
	# Hit-testing must skip locked piece
	_assert(handler.hit_test_piece(Vector2(450, 500)) == "", "Hit test ignores locked piece", results)
	
	# LMB press on locked piece must not grab it
	var mb_down := InputEventMouseButton.new()
	mb_down.button_index = MOUSE_BUTTON_LEFT
	mb_down.pressed = true
	var handled := handler.handle_gui_input(mb_down, Vector2(450, 500))
	_assert(not handled, "Cannot grab locked piece", results)
	_assert(handler.held_piece_id == "", "held_piece_id remains empty", results)

static func test_hover_detection(results: Dictionary) -> void:
	var controller := RestorationController.new()
	controller.initialize_puzzle(_create_test_puzzle(), Vector2(500, 500), false)
	controller.set_piece_position("p1", Vector2(200, 200))
	
	var handler := RestorationInputHandler.new(controller, { "p1": Vector2(100, 100) })
	
	var hover_events: Array[Dictionary] = []
	handler.piece_hover_changed.connect(func(piece_id: String, is_hovered: bool) -> void:
		hover_events.append({"piece_id": piece_id, "is_hovered": is_hovered})
	)
	
	# Move mouse onto p1
	var mm1 := InputEventMouseMotion.new()
	handler.handle_gui_input(mm1, Vector2(200, 200))
	_assert(handler.hovered_piece_id == "p1", "Hover detected p1", results)
	_assert(hover_events.size() == 1 and hover_events[0]["piece_id"] == "p1" and hover_events[0]["is_hovered"] == true, "Hover started emitted", results)
	
	# Move mouse away from p1
	var mm2 := InputEventMouseMotion.new()
	handler.handle_gui_input(mm2, Vector2(800, 800))
	_assert(handler.hovered_piece_id == "", "Hover cleared", results)
	_assert(hover_events.size() == 2 and hover_events[1]["piece_id"] == "p1" and hover_events[1]["is_hovered"] == false, "Hover ended emitted", results)

static func test_cancel_drag(results: Dictionary) -> void:
	var controller := RestorationController.new()
	controller.initialize_puzzle(_create_test_puzzle(), Vector2(500, 500), false)
	controller.set_piece_position("p1", Vector2(200, 200))
	
	var handler := RestorationInputHandler.new(controller, { "p1": Vector2(100, 100) })
	
	var mb_down := InputEventMouseButton.new()
	mb_down.button_index = MOUSE_BUTTON_LEFT
	mb_down.pressed = true
	handler.handle_gui_input(mb_down, Vector2(200, 200))
	_assert(handler.held_piece_id == "p1", "p1 held", results)
	
	handler.cancel_drag()
	_assert(handler.held_piece_id == "", "Held piece cleared on cancel_drag", results)
	_assert(handler.drag_offset == Vector2.ZERO, "Drag offset reset on cancel", results)
