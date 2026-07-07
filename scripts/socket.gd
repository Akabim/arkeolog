extends Area2D

@export var relic_id: String = "stone_1"
@export var symbol_char: String = "ha"
@export var tolerance_radius: float = 16.0

@onready var visual: Node2D = $Visual

var is_solved: bool = false

var sprite: Sprite2D = null

func _ready() -> void:
	collision_layer = 0
	collision_mask = 4 # Detect Stone Blocks (Layer 3)
	
	# Instantiate Sprite2D to hold baked texture
	sprite = Sprite2D.new()
	sprite.name = "Sprite"
	visual.add_child(sprite)
	visual.set_script(null) # Remove custom drawing
	
	update_socket_texture()

func update_socket_texture() -> void:
	if not sprite: return
	var suffix = "_on" if is_solved else "_off"
	var tex_key = "socket_" + symbol_char + suffix
	sprite.texture = Global.get_texture(tex_key)

func _physics_process(_delta: float) -> void:
	var overlapping = get_overlapping_bodies()
	var matching_block: RigidBody2D = null
	
	for body in overlapping:
		if body is RigidBody2D and body.get("relic_id") == relic_id:
			matching_block = body
			break
			
	if matching_block:
		var distance = global_position.distance_to(matching_block.global_position)
		var within_tolerance = distance <= tolerance_radius
		
		if within_tolerance != is_solved:
			is_solved = within_tolerance
			if is_solved:
				Global.solved_sockets[relic_id] = true
				Global.play_sfx.emit("socket_lock")
				Global.camera_shake.emit(1.5, 0.15)
				check_level_completion()
				update_socket_texture()
			else:
				if Global.solved_sockets.has(relic_id):
					Global.solved_sockets.erase(relic_id)
				update_socket_texture()
	else:
		if is_solved:
			is_solved = false
			if Global.solved_sockets.has(relic_id):
				Global.solved_sockets.erase(relic_id)
			update_socket_texture()

func check_level_completion() -> void:
	if Global.solved_sockets.size() == Global.total_sockets_in_level and Global.total_sockets_in_level > 0:
		Global.level_restored.emit()
