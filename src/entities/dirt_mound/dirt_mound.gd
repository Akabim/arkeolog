extends Area2D

@export var relic_id: String = "stone_1"
@export var relic_name: String = "Relic"
@export var symbol_char: String = "ha" # From Hanacaraka (ha, na, ca, ra, ka)

@onready var visual: Node2D = $Visual
@onready var prompt: Node2D = $Prompt

enum MoundState { GRASS, DIRT, CLEANED }
var current_mound_state: MoundState = MoundState.GRASS

var player_near = false
var is_cleaned = false
var current_player: CharacterBody2D = null
@onready var sprite: Sprite2D = $Visual/Sprite2D

var hold_time: float = 0.0
var required_hold_time: float = 2.0
var is_being_held: bool = false
var is_click_started_on_mound: bool = false

# Preload StoneBlock to spawn after cleaning
const STONE_BLOCK_SCENE = preload("res://src/entities/stone_block/stone_block.tscn")

func _ready() -> void:
	# Enable Y-sorting for cozy depth sorting
	y_sort_enabled = true
	
	collision_layer = 8 # Layer 4 (Interactables)
	collision_mask = 2 # Detect Player
	body_entered.connect(_on_player_entered)
	body_exited.connect(_on_player_exited)
	prompt.visible = false
	
	# If already discovered globally, start as cleaned (hole)
	if relic_id in Global.discovered_symbols:
		current_mound_state = MoundState.CLEANED
		is_cleaned = true
		disable_collisions()
		call_deferred("spawn_stone_block")
	else:
		current_mound_state = MoundState.GRASS
		
	setup_visual()

func disable_collisions() -> void:
	collision_layer = 0
	collision_mask = 0
	if has_node("SolidBody"):
		var solid_body = $SolidBody
		solid_body.collision_layer = 0
		solid_body.collision_mask = 0

func setup_visual() -> void:
	var tex_key = "gundukan_rumput"
	if current_mound_state == MoundState.DIRT:
		tex_key = "gundukan_1"
	elif current_mound_state == MoundState.CLEANED:
		tex_key = "lubang"
		
	var tex_mound = Global.textures.get(tex_key)
	if not tex_mound:
		if current_mound_state == MoundState.GRASS:
			tex_mound = load("res://assets/textures/player/envi/gundukan rumput.png")
		elif current_mound_state == MoundState.DIRT:
			tex_mound = load("res://assets/textures/player/envi/Gundukan Tanah 1.png")
		else:
			tex_mound = load("res://assets/textures/player/envi/lubang.png")
			
	if sprite:
		sprite.texture = tex_mound
		if current_mound_state == MoundState.CLEANED:
			sprite.z_index = -1
			sprite.show_behind_parent = true
		else:
			sprite.z_index = 0
			sprite.show_behind_parent = false

func _on_player_entered(body: Node2D) -> void:
	if is_cleaned: return
	if body.name == "Player":
		player_near = true
		current_player = body
		prompt.visible = true
		
		# Set prompt type: hold for grass, click for dirt
		if prompt.has_method("set_prompt_type"):
			if current_mound_state == MoundState.GRASS:
				prompt.set_prompt_type("hold")
			else:
				prompt.set_prompt_type("click")
				
		var tween = create_tween()
		prompt.scale = Vector2.ZERO
		tween.tween_property(prompt, "scale", Vector2.ONE, 0.15).set_trans(Tween.TRANS_BACK)

func _on_player_exited(body: Node2D) -> void:
	if body.name == "Player":
		player_near = false
		current_player = null
		is_being_held = false
		is_click_started_on_mound = false
		hold_time = 0.0
		queue_redraw()
		
		var tween = create_tween()
		tween.tween_property(prompt, "scale", Vector2.ZERO, 0.1).set_trans(Tween.TRANS_SINE)
		tween.tween_callback(func(): prompt.visible = false)

func _process(delta: float) -> void:
	if is_cleaned: return
	if Global.current_state != Global.State.OVERWORLD:
		is_being_held = false
		is_click_started_on_mound = false
		hold_time = 0.0
		queue_redraw()
		return
	
	# Update prompt modulate based on whether player has correct tool equipped
	if player_near and current_player:
		var has_correct_tool = current_player.current_tool == "shovel" or current_player.current_tool == "pickaxe"
		if has_correct_tool:
			prompt.modulate = Color(1, 1, 1)
		else:
			prompt.modulate = Color(1.0, 0.4, 0.4)
			
		# Handle mouse hold action
		var mouse_pos = get_global_mouse_position()
		var is_mouse_over = global_position.distance_to(mouse_pos) < 70.0
		
		if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
			if not is_click_started_on_mound and is_mouse_over:
				is_click_started_on_mound = true
		else:
			is_click_started_on_mound = false
			
		if is_click_started_on_mound:
			if has_correct_tool:
				is_being_held = true
				hold_time += delta
				current_player.swing_tool()
				queue_redraw()
				
				if current_mound_state == MoundState.GRASS:
					if hold_time >= required_hold_time:
						current_mound_state = MoundState.DIRT
						hold_time = 0.0
						is_being_held = false
						is_click_started_on_mound = false
						Global.play_sfx.emit("dig")
						setup_visual()
						if prompt.has_method("set_prompt_type"):
							prompt.set_prompt_type("click")
				elif current_mound_state == MoundState.DIRT:
					# Excavate
					interact(current_player)
					hold_time = 0.0
					is_being_held = false
					is_click_started_on_mound = false
			else:
				is_being_held = false
				hold_time = 0.0
				queue_redraw()
		else:
			is_being_held = false
			if hold_time > 0.0:
				hold_time = max(0.0, hold_time - delta * 2.0)
				queue_redraw()

func _draw() -> void:
	if is_being_held and hold_time > 0.0 and current_mound_state == MoundState.GRASS:
		var center = Vector2(0, -64)
		var radius = 18.0
		var progress = clamp(hold_time / required_hold_time, 0.0, 1.0)
		
		# Draw dark background circle
		draw_circle(center, radius + 3, Color(0, 0, 0, 0.5))
		
		# Draw progress arc
		draw_arc(center, radius, -PI/2, -PI/2 + progress * TAU, 32, Color(0.3, 0.85, 0.3), 4.0, true)

func interact(_player: CharacterBody2D) -> void:
	if is_cleaned or current_mound_state != MoundState.DIRT: return
	# Switch to excavation game state
	Global.change_state(Global.State.EXCAVATION)
	Global.excavation_started.emit(self)
	prompt.visible = false
	Global.play_sfx.emit("zoom")

func complete_cleaning() -> void:
	is_cleaned = true
	current_mound_state = MoundState.CLEANED
	
	var translation = ""
	if Global.dictionary.has(relic_id):
		translation = Global.dictionary[relic_id]["translation"]
		
	# Add to discovered list if not already there
	if not relic_id in Global.discovered_symbols:
		Global.discovered_symbols.append(relic_id)
		
	Global.excavation_completed.emit(relic_id, relic_name, symbol_char, translation)
	
	# Spawn dust/dirt particle burst
	Global.camera_shake.emit(3.0, 0.3)
	Global.play_sfx.emit("relic_uncovered")
	
	# Spawn the physics-based stone block
	spawn_stone_block()
	
	# Disable interaction and update visual to hole
	disable_collisions()
	prompt.visible = false
	setup_visual()

func spawn_stone_block() -> void:
	var stone = STONE_BLOCK_SCENE.instantiate()
	stone.position = position
	stone.relic_id = relic_id
	stone.symbol_char = symbol_char
	stone.relic_name = relic_name
	get_parent().add_child(stone)
