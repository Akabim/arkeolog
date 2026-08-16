extends SceneTree

const RestorationCoreTest = preload("res://src/core/restoration/restoration_core_test.gd")
const RestorationInputTest = preload("res://src/core/restoration/restoration_input_test.gd")

func _init() -> void:
	print("--- Running Restoration Core Tests ---")
	var core_results: Dictionary = RestorationCoreTest.run_all_tests()
	print("Core Tests: Total: %d, Passed: %d, Failed: %d" % [core_results["total"], core_results["passed"], core_results["failed"]])
	for err in core_results["errors"]:
		printerr(err)

	print("\n--- Running Restoration Input Tests ---")
	var input_results: Dictionary = RestorationInputTest.run_all_tests()
	print("Input Tests: Total: %d, Passed: %d, Failed: %d" % [input_results["total"], input_results["passed"], input_results["failed"]])
	for err in input_results["errors"]:
		printerr(err)

	var all_ok: bool = (core_results["failed"] == 0) and (input_results["failed"] == 0)
	if all_ok:
		print("\n[ALL RESTORATION TESTS PASSED]")
		quit(0)
	else:
		printerr("\n[SOME TESTS FAILED]")
		quit(1)
