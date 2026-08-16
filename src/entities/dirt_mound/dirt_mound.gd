extends Area2D

@export var required_tool: Global.ToolType = Global.ToolType.SHOVEL
@export var relic_id: String = "stone_1"
@export var relic_name: String = "Relic"
@export var symbol_char: String = "ha" # From Hanacaraka (ha, na, ca, ra, ka)

@onready var visual: Node2D = $Visual
@onready var prompt: Node2D = $Prompt
@onready var sprite: Sprite2D = $Visual/Sprite2D

enum MoundState { GRASS, DIRT, CLEANED }
var current_mound_state: MoundState = MoundState.GRASS

var player_near: bool = false
var is_cleaned: bool = false
var current_player: CharacterBody2D = null

var hold_time: float = 0.0
var required_hold_time: float = 2.0
var is_being_held: bool = false
var is_click_started_on_mound: bool = false

# Preload StoneBlock to spawn after cleaning
const STONE_BLOCK_SCENE: PackedScene = preload("res://src/entities/stone_block/stone_block.tscn")
var tex_lubang: Texture2D = preload("res://assets/textures/environment/lubang.png")


func _ready() -> void:
	y_sort_enabled = true
	collision_layer = 8 # Layer 4 (Interactables)
	collision_mask = 2 # Detect Player
	body_entered.connect(_on_player_entered)
	body_exited.connect(_on_player_exited)
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	prompt.visible = false
	
	# If already discovered globally, start as cleaned (hole)
	if relic_id in Global.discovered_symbols:
		current_mound_state = MoundState.CLEANED
		is_cleaned = true
		disable_collisions()
	else:
		current_mound_state = MoundState.GRASS
		_set_after_minigame_col_active(false)
		
	setup_visual()

func _set_after_minigame_col_active(active: bool) -> void:
	if has_node("AfterMinigameCol"):
		var after_col: StaticBody2D = $AfterMinigameCol as StaticBody2D
		if after_col:
			after_col.collision_layer = 1 if active else 0
			after_col.collision_mask = 0
			for child in after_col.get_children():
				if child is CollisionShape2D:
					(child as CollisionShape2D).set_deferred("disabled", not active)

func disable_collisions() -> void:
	collision_layer = 0
	collision_mask = 0
	if has_node("InteractColl"):
		var interact_coll: CollisionShape2D = $InteractColl as CollisionShape2D
		if interact_coll:
			interact_coll.set_deferred("disabled", true)
	# Disable initial mound SolidBody
	if has_node("SolidBody"):
		var solid_body: StaticBody2D = $SolidBody as StaticBody2D
		if solid_body:
			solid_body.collision_layer = 0
			solid_body.collision_mask = 0
			for child in solid_body.get_children():
				if child is CollisionShape2D:
					(child as CollisionShape2D).set_deferred("disabled", true)
	# Enable AfterMinigameCol ONLY after excavation
	_set_after_minigame_col_active(true)

func setup_visual() -> void:
	var tex_key: String = "gundukan_rumput"
	if current_mound_state == MoundState.DIRT:
		tex_key = "gundukan_1"
	elif current_mound_state == MoundState.CLEANED:
		tex_key = "lubang"
		
	var tex_mound: Texture2D = Global.get_texture(tex_key)
	if not tex_mound:
		if current_mound_state == MoundState.GRASS:
			tex_mound = load("res://assets/textures/environment/gundukan rumput.png")
		elif current_mound_state == MoundState.DIRT:
			tex_mound = load("res://assets/textures/environment/Gundukan Tanah 1.png")
		else:
			tex_mound = tex_lubang
			
	if sprite:
		sprite.texture = tex_mound
		sprite.centered = true
		sprite.position = Vector2.ZERO
		sprite.offset = Vector2(0, -32)
		sprite.scale = Vector2(0.45, 0.45)
		sprite.z_index = 0
		sprite.show_behind_parent = false
		z_index = 0

func _on_player_entered(body: Node2D) -> void:
	if is_cleaned: return
	if body.name == "Player":
		player_near = true
		current_player = body as CharacterBody2D
		prompt.visible = true
		
		# Set prompt type: hold for grass, click for dirt
		if prompt.has_method("set_prompt_type"):
			if current_mound_state == MoundState.GRASS:
				prompt.set_prompt_type("hold")
			else:
				prompt.set_prompt_type("click")
				
		var tween: Tween = create_tween()
		prompt.scale = Vector2.ZERO
		tween.tween_property(prompt, "scale", Vector2.ONE, 0.15).set_trans(Tween.TRANS_BACK)

func _on_mouse_entered() -> void:
	if is_cleaned: return
	Global.set_contextual_cursor(required_tool)

func _on_mouse_exited() -> void:
	Global.reset_cursor()

func _on_player_exited(body: Node2D) -> void:
	if body.name == "Player":
		player_near = false
		current_player = null
		is_being_held = false
		is_click_started_on_mound = false
		hold_time = 0.0
		queue_redraw()
		
		var tween: Tween = create_tween()
		tween.tween_property(prompt, "scale", Vector2.ZERO, 0.1).set_trans(Tween.TRANS_SINE)
		tween.tween_callback(func() -> void: prompt.visible = false)

func position_player_at_mound(player: CharacterBody2D) -> void:
	if not player: return
	var marker: Marker2D = get_node_or_null("Marker2D") as Marker2D
	var is_left: bool = player.global_position.x < global_position.x
	
	var target_pos: Vector2 = Vector2.ZERO
	if marker:
		var offset_x: float = -abs(marker.position.x) if is_left else abs(marker.position.x)
		var offset_y: float = marker.position.y
		target_pos = global_position + Vector2(offset_x, offset_y)
	else:
		var side_x: float = -59.0 if is_left else 59.0
		target_pos = global_position + Vector2(side_x, -40.0)
		
	var tween: Tween = create_tween()
	tween.tween_property(player, "global_position", target_pos, 0.12).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	
	if player.has_method("set_vertical_facing"):
		player.call("set_vertical_facing", "front")
	
	if player.has_node("Visual"):
		var player_visual: Node2D = player.get_node("Visual") as Node2D
		if player_visual:
			var base_s: float = abs(player_visual.scale.x)
			if is_left:
				player_visual.scale.x = -base_s
			else:
				player_visual.scale.x = base_s

func spawn_dirt_particles(is_grass: bool = false) -> void:
	var particles: CPUParticles2D = CPUParticles2D.new()
	particles.global_position = global_position + Vector2(0, -15)
	particles.amount = 16
	particles.lifetime = 0.5
	particles.one_shot = true
	particles.explosiveness = 1.0
	particles.direction = Vector2.UP
	particles.spread = 60.0
	particles.initial_velocity_min = 80.0
	particles.initial_velocity_max = 160.0
	particles.gravity = Vector2(0, 300)
	particles.scale_amount_min = 2.0
	particles.scale_amount_max = 4.0
	
	var base_color: Color = Color(0.35, 0.55, 0.25) if is_grass else Color(0.45, 0.32, 0.18)
	particles.color = base_color
		
	var grad: Gradient = Gradient.new()
	grad.colors = PackedColorArray([base_color, Color(base_color.r, base_color.g, base_color.b, 0.0)])
	grad.offsets = PackedFloat32Array([0.0, 1.0])
	particles.color_ramp = grad

	var target_parent: Node = get_parent()
	if target_parent:
		target_parent.add_child(particles)
	else:
		add_child(particles)
		
	particles.emitting = true
	
	var timer: SceneTreeTimer = get_tree().create_timer(particles.lifetime + 0.2)
	timer.timeout.connect(particles.queue_free)

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
		prompt.modulate = Color(1, 1, 1)
			
		# Handle mouse hold action
		var mouse_pos: Vector2 = get_global_mouse_position()
		var is_mouse_over: bool = global_position.distance_to(mouse_pos) < 70.0
		
		if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
			if not is_click_started_on_mound and is_mouse_over:
				is_click_started_on_mound = true
				# Auto-equip shovel if not already equipped with shovel or pickaxe
				var cur_tool: String = current_player.get("current_tool") as String
				if cur_tool != "shovel" and cur_tool != "pickaxe":
					current_player.set("current_tool", "shovel")
					if current_player.has_method("update_tool_visual"):
						current_player.call("update_tool_visual")
						
				position_player_at_mound(current_player)
		else:
			is_click_started_on_mound = false
			
		if is_click_started_on_mound:
			var has_correct_tool: bool = current_player.get("current_tool") == "shovel" or current_player.get("current_tool") == "pickaxe"
			if has_correct_tool:
				is_being_held = true
				hold_time += delta
				
				var was_swinging: bool = false
				if current_player.has_method("check_swinging"):
					was_swinging = current_player.call("check_swinging") as bool
				if current_player.has_method("swing_tool"):
					current_player.call("swing_tool")
				if not was_swinging:
					spawn_dirt_particles(current_mound_state == MoundState.GRASS)
					
				queue_redraw()
				
				if current_mound_state == MoundState.GRASS:
					if hold_time >= required_hold_time:
						current_mound_state = MoundState.DIRT
						hold_time = 0.0
						is_being_held = false
						is_click_started_on_mound = false
						
						position_player_at_mound(current_player)
						spawn_dirt_particles(true)
						Global.camera_shake.emit(1.5, 0.15)
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

func _unhandled_input(event: InputEvent) -> void:
	if is_cleaned or not player_near or not current_player: return
	if Global.current_state != Global.State.OVERWORLD: return
	
	if event.is_action_pressed("interact") or event.is_action_pressed("ui_accept"):
		# Auto-equip shovel if not already equipped with shovel or pickaxe
		var cur_tool: String = current_player.get("current_tool") as String
		if cur_tool != "shovel" and cur_tool != "pickaxe":
			current_player.set("current_tool", "shovel")
			if current_player.has_method("update_tool_visual"):
				current_player.call("update_tool_visual")
				
		position_player_at_mound(current_player)
		
		var was_swinging: bool = false
		if current_player.has_method("check_swinging"):
			was_swinging = current_player.call("check_swinging") as bool
		if current_player.has_method("swing_tool"):
			current_player.call("swing_tool")
			
		spawn_dirt_particles(current_mound_state == MoundState.GRASS)
		
		if current_mound_state == MoundState.DIRT:
			interact(current_player)
		elif current_mound_state == MoundState.GRASS:
			current_mound_state = MoundState.DIRT
			hold_time = 0.0
			is_being_held = false
			is_click_started_on_mound = false
			Global.camera_shake.emit(1.5, 0.15)
			Global.play_sfx.emit("dig")
			setup_visual()
			if prompt.has_method("set_prompt_type"):
				prompt.set_prompt_type("click")
				
		get_viewport().set_input_as_handled()

func _draw() -> void:
	if is_being_held and hold_time > 0.0 and current_mound_state == MoundState.GRASS:
		var center: Vector2 = Vector2(0, -60)
		var radius: float = 18.0
		var progress: float = clamp(hold_time / required_hold_time, 0.0, 1.0)
		
		# Draw dark background circle
		draw_circle(center, radius + 3.0, Color(0, 0, 0, 0.5))
		
		# Draw progress arc
		draw_arc(center, radius, -PI/2.0, -PI/2.0 + progress * TAU, 32, Color(0.3, 0.85, 0.3), 4.0, true)

func interact(player: CharacterBody2D = null) -> void:
	if is_cleaned or current_mound_state != MoundState.DIRT: return
	var target_player: CharacterBody2D = player if player != null else current_player
	if target_player != null:
		position_player_at_mound(target_player)
		
	spawn_dirt_particles(false)
	Global.camera_shake.emit(1.5, 0.15)
	Global.play_sfx.emit("dig")
	
	# Switch to excavation game state
	Global.change_state(Global.State.EXCAVATION)
	Global.excavation_started.emit(self)
	prompt.visible = false
	Global.play_sfx.emit("zoom")

func start_excavation(player: CharacterBody2D = null) -> void:
	interact(player)

func complete_cleaning() -> void:
	is_cleaned = true
	current_mound_state = MoundState.CLEANED
	Global.reset_cursor()
	if sprite:
		sprite.texture = tex_lubang
	disable_collisions()
	
	var translation: String = ""
	if Global.dictionary.has(relic_id):
		var r_data = Global.dictionary[relic_id]
		if r_data is Dictionary and r_data.has("translation"):
			translation = r_data["translation"]
		elif r_data is RelicData and r_data.get("translation") != null:
			translation = r_data.translation
		
	# Add to discovered list if not already there
	if not relic_id in Global.discovered_symbols:
		Global.discovered_symbols.append(relic_id)
		
	Global.excavation_completed.emit(relic_id, relic_name, symbol_char, translation)
	
	# Spawn dust/dirt particle burst
	Global.camera_shake.emit(3.0, 0.3)
	Global.play_sfx.emit("relic_uncovered")
	
	# Disable interaction and update visual to hole
	prompt.visible = false
	setup_visual()

func spawn_stone_block() -> void:
	var stone: Node2D = STONE_BLOCK_SCENE.instantiate() as Node2D
	if not stone: return
	stone.position = position
	stone.set("relic_id", relic_id)
	stone.set("symbol_char", symbol_char)
	stone.set("relic_name", relic_name)
	# Add stone to the level root (not a container) for proper y-sorting
	# If this mound is inside a container (e.g. DirtMounds), go up to level root
	var target_parent: Node = get_parent()
	while target_parent and target_parent.get_parent() and target_parent.get_parent() is Node2D and target_parent.get_parent().get("y_sort_enabled"):
		target_parent = target_parent.get_parent()
	if target_parent:
		target_parent.add_child(stone)
