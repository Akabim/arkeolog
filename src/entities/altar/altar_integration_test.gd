class_name AltarIntegrationTest
extends RefCounted

const InventoryManagerScript = preload("res://src/core/inventory_manager.gd")
const GlobalScript = preload("res://src/core/global.gd")

static func run_all_tests() -> Dictionary:
	var results = {
		"total": 0,
		"passed": 0,
		"failed": 0,
		"errors": []
	}
	
	test_inventory_manager_has_fragment(results)
	test_inventory_manager_duplicate_noop(results)
	test_global_state_restoration(results)
	test_altar_completeness_calculation(results)
	test_altar_incomplete_interaction(results)
	test_altar_complete_interaction(results)
	test_altar_puzzle_data_integrity(results)
	
	return results

static func assert_true(condition: bool, message: String, results: Dictionary) -> void:
	results["total"] += 1
	if condition:
		results["passed"] += 1
		print("  PASS: %s" % message)
	else:
		results["failed"] += 1
		var err_msg = "  FAIL: %s" % message
		results["errors"].append(err_msg)
		printerr(err_msg)

static func assert_false(condition: bool, message: String, results: Dictionary) -> void:
	assert_true(not condition, message, results)

static func assert_eq(actual, expected, message: String, results: Dictionary) -> void:
	results["total"] += 1
	if actual == expected:
		results["passed"] += 1
		print("  PASS: %s" % message)
	else:
		results["failed"] += 1
		var err_msg = "  FAIL: %s (expected: %s, got: %s)" % [message, str(expected), str(actual)]
		results["errors"].append(err_msg)
		printerr(err_msg)

static func _create_test_puzzle() -> RestorationPuzzleData:
	var puzzle = RestorationPuzzleData.new()
	puzzle.artifact_id = "cat_statue"
	
	var p1 = JigsawPieceData.new()
	p1.piece_id = "cat_statue_p01"
	p1.target_offset = Vector2(-40, 0)
	
	var p2 = JigsawPieceData.new()
	p2.piece_id = "cat_statue_p02"
	p2.target_offset = Vector2(0, 0)
	
	var p3 = JigsawPieceData.new()
	p3.piece_id = "cat_statue_p03"
	p3.target_offset = Vector2(40, 0)
	
	var pieces_arr: Array[JigsawPieceData] = [p1, p2, p3]
	puzzle.pieces = pieces_arr
	return puzzle

static func test_inventory_manager_has_fragment(results: Dictionary) -> void:
	print("[AltarIntegrationTest] test_inventory_manager_has_fragment")
	var inv = InventoryManagerScript.new()
	
	assert_false(inv.has_fragment("cat_statue_p01"), "Empty inventory does not have cat_statue_p01", results)
	
	inv.add_fragment("cat_statue_p01")
	assert_true(inv.has_fragment("cat_statue_p01"), "has_fragment returns true after add", results)
	assert_false(inv.has_fragment("cat_statue_p02"), "has_fragment returns false for uncollected piece", results)
	inv.free()

static func test_inventory_manager_duplicate_noop(results: Dictionary) -> void:
	print("[AltarIntegrationTest] test_inventory_manager_duplicate_noop")
	var inv = InventoryManagerScript.new()
	
	inv.add_fragment("cat_statue_p01")
	var count_after_first = inv.get_fragment_count("cat_statue_p01")
	assert_eq(count_after_first, 1, "Count after first add is 1", results)
	
	inv.add_fragment("cat_statue_p01")
	var count_after_second = inv.get_fragment_count("cat_statue_p01")
	assert_eq(count_after_second, 1, "Duplicate add is no-op, count remains 1", results)
	inv.free()

static func test_global_state_restoration(results: Dictionary) -> void:
	print("[AltarIntegrationTest] test_global_state_restoration")
	var glob = GlobalScript.new()
	assert_true("RESTORATION" in glob.State.keys(), "Global.State.RESTORATION enum exists", results)
	
	glob.change_state(glob.State.OVERWORLD)
	assert_eq(glob.current_state, glob.State.OVERWORLD, "Global starts in OVERWORLD", results)
	
	glob.change_state(glob.State.RESTORATION)
	assert_eq(glob.current_state, glob.State.RESTORATION, "Global changes to RESTORATION", results)
	glob.free()

static func test_altar_completeness_calculation(results: Dictionary) -> void:
	print("[AltarIntegrationTest] test_altar_completeness_calculation")
	var altar_scene = load("res://src/entities/altar/altar.tscn")
	var altar = altar_scene.instantiate()
	var inv = InventoryManagerScript.new()
	altar.inventory = inv
	var puzzle = _create_test_puzzle()
	altar.puzzle_data = puzzle
	
	# 0/3
	var s0 = altar.check_completeness()
	assert_eq(s0.owned, 0, "0/3 owned pieces", results)
	assert_eq(s0.total, 3, "3 total pieces", results)
	assert_false(s0.is_complete, "0/3 is not complete", results)
	
	# 1/3
	inv.add_fragment("cat_statue_p01")
	var s1 = altar.check_completeness()
	assert_eq(s1.owned, 1, "1/3 owned pieces", results)
	assert_false(s1.is_complete, "1/3 is not complete", results)
	
	# 2/3
	inv.add_fragment("cat_statue_p02")
	var s2 = altar.check_completeness()
	assert_eq(s2.owned, 2, "2/3 owned pieces", results)
	assert_false(s2.is_complete, "2/3 is not complete", results)
	
	# 3/3
	inv.add_fragment("cat_statue_p03")
	var s3 = altar.check_completeness()
	assert_eq(s3.owned, 3, "3/3 owned pieces", results)
	assert_true(s3.is_complete, "3/3 is complete", results)
	
	altar.free()
	inv.free()

static func test_altar_incomplete_interaction(results: Dictionary) -> void:
	print("[AltarIntegrationTest] test_altar_incomplete_interaction")
	var altar_scene = load("res://src/entities/altar/altar.tscn")
	var altar = altar_scene.instantiate()
	var inv = InventoryManagerScript.new()
	altar.inventory = inv
	var puzzle = _create_test_puzzle()
	altar.puzzle_data = puzzle
	
	# 1/3 pieces owned
	inv.add_fragment("cat_statue_p01")
	
	var holder = {"signal_emitted": false}
	altar.restoration_requested.connect(func(_p): holder["signal_emitted"] = true)
	
	altar.interact()
	
	assert_false(holder["signal_emitted"], "Incomplete altar does not emit restoration_requested", results)
	
	altar.free()
	inv.free()

static func test_altar_complete_interaction(results: Dictionary) -> void:
	print("[AltarIntegrationTest] test_altar_complete_interaction")
	var altar_scene = load("res://src/entities/altar/altar.tscn")
	var altar = altar_scene.instantiate()
	var inv = InventoryManagerScript.new()
	altar.inventory = inv
	var puzzle = _create_test_puzzle()
	altar.puzzle_data = puzzle
	
	# All 3 pieces owned
	inv.add_fragment("cat_statue_p01")
	inv.add_fragment("cat_statue_p02")
	inv.add_fragment("cat_statue_p03")
	
	var holder = {"received_puzzle": null}
	altar.restoration_requested.connect(func(p): holder["received_puzzle"] = p)
	
	altar.interact()
	
	assert_true(holder["received_puzzle"] != null, "Complete altar emits restoration_requested", results)
	if holder["received_puzzle"] != null:
		assert_eq(holder["received_puzzle"].artifact_id, "cat_statue", "Passed exact puzzle data", results)
	
	altar.free()
	inv.free()

static func test_altar_puzzle_data_integrity(results: Dictionary) -> void:
	print("[AltarIntegrationTest] test_altar_puzzle_data_integrity")
	var puzzle = _create_test_puzzle()
	assert_eq(puzzle.pieces.size(), 3, "Puzzle data has 3 pieces", results)
	assert_eq(puzzle.pieces[0].piece_id, "cat_statue_p01", "Piece 1 ID follows contract", results)
	assert_eq(puzzle.pieces[1].piece_id, "cat_statue_p02", "Piece 2 ID follows contract", results)
	assert_eq(puzzle.pieces[2].piece_id, "cat_statue_p03", "Piece 3 ID follows contract", results)
