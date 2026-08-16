extends Node

signal inventory_updated

var collected_fragments: Dictionary = {}
var assembled_artifacts: Array = []

func add_fragment(fragment_id: String) -> void:
	if fragment_id.is_empty():
		return
	if collected_fragments.has(fragment_id):
		collected_fragments[fragment_id] += 1
	else:
		collected_fragments[fragment_id] = 1
	inventory_updated.emit()

func remove_fragment(fragment_id: String, amount: int = 1) -> bool:
	if collected_fragments.has(fragment_id) and collected_fragments[fragment_id] >= amount:
		collected_fragments[fragment_id] -= amount
		if collected_fragments[fragment_id] <= 0:
			collected_fragments.erase(fragment_id)
		inventory_updated.emit()
		return true
	return false

func get_fragment_count(fragment_id: String) -> int:
	return collected_fragments.get(fragment_id, 0)

func add_artifact(artifact_id: String) -> void:
	if not artifact_id in assembled_artifacts:
		assembled_artifacts.append(artifact_id)
		inventory_updated.emit()

func has_artifact(artifact_id: String) -> bool:
	return artifact_id in assembled_artifacts
