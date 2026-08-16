class_name JigsawPieceState
extends RefCounted

var piece_data: JigsawPieceData
var current_position: Vector2 = Vector2.ZERO
var target_position: Vector2 = Vector2.ZERO
var rotation_step: int = 0 # 0 = 0°, 1 = 90°, 2 = 180°, 3 = 270°
var is_locked: bool = false

func _init(data: JigsawPieceData = null) -> void:
	piece_data = data

func get_piece_id() -> String:
	return piece_data.piece_id if piece_data else ""

func get_rotation_degrees() -> float:
	return rotation_step * 90.0

func get_rotation_radians() -> float:
	return rotation_step * (PI / 2.0)
