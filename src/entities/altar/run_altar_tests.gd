extends SceneTree

const AltarIntegrationTest = preload("res://src/entities/altar/altar_integration_test.gd")

func _init() -> void:
	print("--- Running Altar Integration Tests ---")
	var results: Dictionary = AltarIntegrationTest.run_all_tests()
	print("\nAltar Tests: Total: %d, Passed: %d, Failed: %d" % [results["total"], results["passed"], results["failed"]])
	for err in results["errors"]:
		printerr(err)

	if results["failed"] == 0:
		print("\n[ALL ALTAR INTEGRATION TESTS PASSED]")
		quit(0)
	else:
		printerr("\n[SOME ALTAR INTEGRATION TESTS FAILED]")
		quit(1)
