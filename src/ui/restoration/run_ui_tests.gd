extends SceneTree

const RestorationUiTest = preload("res://src/ui/restoration/restoration_ui_test.gd")

func _init() -> void:
	print("--- Running Restoration UI Tests ---")
	var ui_results: Dictionary = RestorationUiTest.run_all_tests()
	print("UI Tests: Total: %d, Passed: %d, Failed: %d" % [ui_results["total"], ui_results["passed"], ui_results["failed"]])
	for err in ui_results["errors"]:
		printerr(err)

	if ui_results["failed"] == 0:
		print("\n[ALL RESTORATION UI TESTS PASSED]")
		quit(0)
	else:
		printerr("\n[SOME RESTORATION UI TESTS FAILED]")
		quit(1)
