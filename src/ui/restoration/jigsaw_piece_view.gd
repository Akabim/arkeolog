class_name JigsawPieceView
extends Control

@onready var texture_display: TextureRect = $TextureDisplay

var piece_id: String = ""
var is_locked: bool = false
var outline_material: ShaderMaterial = null
var outline_shader: Shader = preload("res://src/ui/excavation/tool_outline.gdshader")

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	if not texture_display and has_node("TextureDisplay"):
		texture_display = $TextureDisplay
	if texture_display:
		texture_display.mouse_filter = Control.MOUSE_FILTER_IGNORE

func setup(p_piece_id: String, texture: Texture2D, initial_position: Vector2, initial_rotation_degrees: float) -> void:
	piece_id = p_piece_id
	if not texture_display and has_node("TextureDisplay"):
		texture_display = $TextureDisplay
		
	if texture:
		if texture_display:
			texture_display.texture = texture
		custom_minimum_size = texture.get_size()
		size = texture.get_size()
	else:
		custom_minimum_size = Vector2(100.0, 100.0)
		size = Vector2(100.0, 100.0)
		
	pivot_offset = size / 2.0
	_setup_shader()
	set_visual_position(initial_position)
	set_visual_rotation(initial_rotation_degrees)
	set_hovered(false)
	set_locked(false)

func _setup_shader() -> void:
	outline_material = ShaderMaterial.new()
	outline_material.shader = outline_shader
	outline_material.set_shader_parameter("enabled", false)
	outline_material.set_shader_parameter("outline_color", Color(1.0, 1.0, 1.0, 0.9))
	outline_material.set_shader_parameter("width", 3.0)
	if texture_display:
		texture_display.material = outline_material

func set_hovered(p_hovered: bool) -> void:
	if is_locked:
		if outline_material:
			outline_material.set_shader_parameter("enabled", false)
		return
	if outline_material:
		outline_material.set_shader_parameter("enabled", p_hovered)

func set_locked(p_locked: bool) -> void:
	is_locked = p_locked
	if is_locked:
		set_hovered(false)
		z_index = 0
	else:
		z_index = 1

func set_visual_position(center_pos: Vector2) -> void:
	position = center_pos - pivot_offset

func set_visual_rotation(deg: float) -> void:
	rotation_degrees = deg

func animate_snap(target_center: Vector2) -> void:
	set_locked(true)
	var tween: Tween = create_tween().set_parallel(true)
	var target_pos: Vector2 = target_center - pivot_offset
	tween.tween_property(self, "position", target_pos, 0.18).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "rotation_degrees", 0.0, 0.18).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	
	var pop_tween: Tween = create_tween()
	pop_tween.tween_property(self, "scale", Vector2(1.08, 1.08), 0.09).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	pop_tween.tween_property(self, "scale", Vector2.ONE, 0.09).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)

func animate_incorrect() -> void:
	var tween: Tween = create_tween()
	tween.tween_property(self, "modulate", Color(1.4, 0.5, 0.5, 1.0), 0.08)
	tween.tween_property(self, "modulate", Color.WHITE, 0.12)
