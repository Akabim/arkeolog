class_name RestorationUiTest
extends RefCounted

const RestorationPuzzleData = preload("res://src/core/resources/restoration_puzzle_data.gd")
const JigsawPieceData = preload("res://src/core/resources/jigsaw_piece_data.gd")
const RestorationOverlayScene = preload("res://src/ui/restoration/restoration_overlay.tscn")
const JigsawPieceViewScene = preload("res://src/ui/restoration/jigsaw_piece_view.tscn")

static func _assert(condition: bool, message: String, results: Dictionary) -> void:
	results["total"] += 1
	if condition:
		results["passed"] += 1
		print("  PASS: %s" % message)
	else:
		results["failed"] += 1
		var err: String = "  FAIL: %s" % message
		results["errors"].append(err)
		printerr(err)

static func run_all_tests() -> Dictionary:
	var results: Dictionary = {
		"total": 0,
		"passed": 0,
		"failed": 0,
		"errors": []
	}
	
	test_scene_instantiation(results)
	test_ui_initialization_and_pieces(results)
	test_piece_view_hover_and_locked(results)
	test_signal_integration(results)
	
	return results

static func _create_test_puzzle() -> RestorationPuzzleData:
	var puzzle := RestorationPuzzleData.new()
	puzzle.artifact_id = "test_artifact"
	puzzle.snap_tolerance = 40.0
	puzzle.radial_radius = 200.0
	
	var p1 := JigsawPieceData.new()
	p1.piece_id = "piece_1"
	p1.target_offset = Vector2(-50.0, 0.0)
	
	var p2 := JigsawPieceData.new()
	p2.piece_id = "piece_2"
	p2.target_offset = Vector2(50.0, 0.0)
	
	puzzle.pieces = [p1, p2]
	return puzzle

static func test_scene_instantiation(results: Dictionary) -> void:
	print("[RestorationUiTest] test_scene_instantiation")
	var overlay: RestorationOverlay = RestorationOverlayScene.instantiate() as RestorationOverlay
	_assert(overlay != null, "RestorationOverlay instantiates from scene", results)
	
	var piece_view: JigsawPieceView = JigsawPieceViewScene.instantiate() as JigsawPieceView
	_assert(piece_view != null, "JigsawPieceView instantiates from scene", results)
	
	overlay.free()
	piece_view.free()

static func test_ui_initialization_and_pieces(results: Dictionary) -> void:
	print("[RestorationUiTest] test_ui_initialization_and_pieces")
	var overlay: RestorationOverlay = RestorationOverlayScene.instantiate() as RestorationOverlay
	var puzzle := _create_test_puzzle()
	
	overlay.start_restoration(puzzle, Vector2(960, 540))
	
	_assert(overlay.piece_views.size() == 2, "Instantiated 2 piece views", results)
	_assert(overlay.piece_views.has("piece_1"), "Has view for piece_1", results)
	_assert(overlay.piece_views.has("piece_2"), "Has view for piece_2", results)
	
	var pv1: JigsawPieceView = overlay.piece_views["piece_1"]
	_assert(pv1.piece_id == "piece_1", "Piece ID matches", results)
	_assert(pv1.is_locked == false, "Piece starts unlocked", results)
	
	overlay.free()

static func test_piece_view_hover_and_locked(results: Dictionary) -> void:
	print("[RestorationUiTest] test_piece_view_hover_and_locked")
	var pv: JigsawPieceView = JigsawPieceViewScene.instantiate() as JigsawPieceView
	pv.setup("p1", null, Vector2(100, 100), 0.0)
	
	pv.set_hovered(true)
	if pv.outline_material:
		var is_enabled: bool = pv.outline_material.get_shader_parameter("enabled")
		_assert(is_enabled == true, "Outline enabled on hover", results)
		
	pv.set_hovered(false)
	if pv.outline_material:
		var is_enabled: bool = pv.outline_material.get_shader_parameter("enabled")
		_assert(is_enabled == false, "Outline disabled when unhovered", results)
		
	pv.set_locked(true)
	_assert(pv.is_locked == true, "View marked locked", results)
	pv.set_hovered(true)
	if pv.outline_material:
		var is_enabled: bool = pv.outline_material.get_shader_parameter("enabled")
		_assert(is_enabled == false, "Locked piece ignores hover outline", results)
		
	pv.free()

static func test_signal_integration(results: Dictionary) -> void:
	print("[RestorationUiTest] test_signal_integration")
	var overlay: RestorationOverlay = RestorationOverlayScene.instantiate() as RestorationOverlay
	var puzzle := _create_test_puzzle()
	
	overlay.start_restoration(puzzle, Vector2(960, 540))
	
	# Simulate core movement
	overlay.controller.set_piece_position("piece_1", Vector2(400, 300))
	var pv1: JigsawPieceView = overlay.piece_views["piece_1"]
	var expected_pos: Vector2 = Vector2(400, 300) - pv1.pivot_offset
	_assert(pv1.position.is_equal_approx(expected_pos), "View position follows core piece_moved", results)
	
	# Simulate rotation
	overlay.controller.set_piece_rotation_step("piece_1", 1)
	_assert(pv1.rotation_degrees == 90.0, "View rotation follows core piece_rotated", results)
	
	# Simulate correct placement
	overlay.controller.set_piece_position("piece_1", overlay.controller.get_piece_state("piece_1").target_position)
	overlay.controller.set_piece_rotation_step("piece_1", 0)
	overlay.controller.release_piece("piece_1")
	_assert(pv1.is_locked == true, "Correct placement locks view", results)
	
	overlay.free()
