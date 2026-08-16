class_name JigsawPieceData
extends Resource

@export var piece_id: String = ""
@export var texture: Texture2D
@export var target_offset: Vector2 = Vector2.ZERO
@export var canonical_rotation: int = 0 # 0 = 0°, 1 = 90°, 2 = 180°, 3 = 270°
