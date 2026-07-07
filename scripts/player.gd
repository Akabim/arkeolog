extends CharacterBody2D

@export var speed: float = 160.0
@export var acceleration: float = 1000.0
@export var friction: float = 800.0
@export var push_force: float = 80.0

@onready var visual: Node2D = $Visual
@onready var sprite: Sprite2D = $Visual/Sprite
@onready var hand_l: Sprite2D = $Visual/HandL
@onready var hand_r: Sprite2D = $Visual/HandR
@onready var tool_sprite: Sprite2D = $Visual/HandL/Tool
@onready var anim: AnimationPlayer = $AnimationPlayer
@onready var interaction_detector: Area2D = $InteractionDetector
@onready var dust_particles: CPUParticles2D = $DustParticles

var current_tool: String = "scythe" # "scythe" or "shovel"

var shake_intensity: float = 0.0
var shake_timer: float = 0.0

func _ready() -> void:
	# Enable Y-sorting for cozy depth sorting
	y_sort_enabled = true
	
	# Enable physics interpolation if available
	if has_method("set_physics_interpolation_mode"):
		set_physics_interpolation_mode(1) # Inherit
	Global.camera_shake.connect(start_camera_shake)
	call_deferred("setup_camera_limits")
	
	# Assign sprite textures using safe get_texture helper
	sprite.texture = Global.get_texture("player")
	hand_l.texture = Global.get_texture("hand")
	hand_r.texture = Global.get_texture("hand")
		
	update_tool_visual()

func update_tool_visual() -> void:
	if not tool_sprite: return
	if current_tool == "scythe":
		tool_sprite.texture = Global.get_texture("scythe")
		tool_sprite.offset = Vector2(0, -12)
	elif current_tool == "shovel":
		tool_sprite.texture = Global.get_texture("shovel")
		tool_sprite.offset = Vector2(0, -12)

func setup_camera_limits() -> void:
	var level = get_parent()
	if level:
		var limit_r = level.get("level_width")
		var limit_b = level.get("level_height")
		if limit_r and limit_b:
			$Camera2D.limit_left = 0
			$Camera2D.limit_top = 0
			$Camera2D.limit_right = int(limit_r)
			$Camera2D.limit_bottom = int(limit_b)

func start_camera_shake(intensity: float, duration: float) -> void:
	shake_intensity = intensity
	shake_timer = duration

func _process(delta: float) -> void:
	if shake_timer > 0.0:
		shake_timer -= delta
		$Camera2D.offset = Vector2(randf_range(-shake_intensity, shake_intensity), randf_range(-shake_intensity, shake_intensity))
		if shake_timer <= 0.0:
			$Camera2D.offset = Vector2.ZERO

func check_swinging() -> bool:
	if not anim: return false
	return anim.current_animation == "swing_scythe" or anim.current_animation == "swing_shovel"

func swing_tool() -> void:
	if check_swinging() or Global.current_state != Global.State.OVERWORLD: return
	
	# Play animation based on tool
	if current_tool == "scythe":
		anim.play("swing_scythe")
		Global.play_sfx.emit("slash") # Sabit slash sound
	else:
		anim.play("swing_shovel")
		Global.play_sfx.emit("dig") # Sekop dig sound
		
	# Perform action check in front of player
	var facing_dir = sign(visual.scale.x)
	var sweep_center = global_position + Vector2(facing_dir * 32, 12)
	
	if current_tool == "scythe":
		# Hit shrubs in front
		var level = get_parent()
		if level:
			# Find all shrubs in level
			var shrubs_node = level.get_node_or_null("Shrubs")
			var targets = []
			if shrubs_node:
				targets = shrubs_node.get_children()
			else:
				targets = level.get_children()
				
			for child in targets:
				if child.has_method("take_damage") and not child.get("is_destroyed"):
					var dist = sweep_center.distance_to(child.global_position)
					if dist < 48.0:
						child.take_damage(1, Vector2(facing_dir, 0))
						
	elif current_tool == "shovel":
		# Dig dirt mounds in front
		var areas = interaction_detector.get_overlapping_areas()
		for area in areas:
			var mound = area if area.has_method("interact") else area.get_parent()
			if mound and mound.has_method("interact") and mound.name.begins_with("DirtMound"):
				var dist = global_position.distance_to(mound.global_position)
				if dist < 64.0:
					mound.interact(self)
					break

func _physics_process(delta: float) -> void:
	# Locked movement in excavation or journal states
	if Global.current_state != Global.State.OVERWORLD:
		velocity = velocity.move_toward(Vector2.ZERO, friction * delta)
		move_and_slide()
		if not check_swinging():
			anim.play("idle")
		return
	
	# Get input direction
	var input_dir := Vector2.ZERO
	input_dir.x = Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
	input_dir.y = Input.get_action_strength("move_down") - Input.get_action_strength("move_up")
	input_dir = input_dir.normalized()
	
	# Apply velocity
	if input_dir != Vector2.ZERO:
		velocity = velocity.move_toward(input_dir * speed, acceleration * delta)
		
		# Face moving direction (flip visual horizontal scale)
		if input_dir.x != 0:
			visual.scale.x = -sign(input_dir.x)
			
		if not check_swinging():
			anim.play("walk")
	else:
		velocity = velocity.move_toward(Vector2.ZERO, friction * delta)
		if not check_swinging():
			anim.play("idle")
	
	move_and_slide()
	
	# Handle dust particle emission based on movement
	if dust_particles:
		var is_moving = velocity.length() > 20.0 and input_dir != Vector2.ZERO
		var is_overworld = Global.current_state == Global.State.OVERWORLD
		dust_particles.emitting = is_moving and is_overworld
	
	# Apply force to rigid bodies (stone blocks)
	for i in get_slide_collision_count():
		var collision = get_slide_collision(i)
		var collider = collision.get_collider()
		if collider is RigidBody2D and collider.has_method("apply_central_force"):
			var direction = -collision.get_normal()
			collider.apply_central_force(direction * push_force * 10.0)
			
			if velocity.length() > 50.0 and randf() < 0.05:
				Global.camera_shake.emit(1.5, 0.1)
				Global.play_sfx.emit("push")

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("journal"):
		toggle_journal()
		get_viewport().set_input_as_handled()
		return
		
	if Global.current_state != Global.State.OVERWORLD:
		return
		
	# Select Scythe (Key 1 or select_scythe action)
	var is_scythe_pressed = (event is InputEventKey and event.pressed and event.keycode == KEY_1)
	if InputMap.has_action("select_scythe") and event.is_action_pressed("select_scythe"):
		is_scythe_pressed = true
		
	if is_scythe_pressed:
		if current_tool != "scythe":
			current_tool = "scythe"
			update_tool_visual()
			Global.play_sfx.emit("stone_scrape")
		get_viewport().set_input_as_handled()
		return
		
	# Select Shovel (Key 2 or select_shovel action)
	var is_shovel_pressed = (event is InputEventKey and event.pressed and event.keycode == KEY_2)
	if InputMap.has_action("select_shovel") and event.is_action_pressed("select_shovel"):
		is_shovel_pressed = true
		
	if is_shovel_pressed:
		if current_tool != "shovel":
			current_tool = "shovel"
			update_tool_visual()
			Global.play_sfx.emit("stone_scrape")
		get_viewport().set_input_as_handled()
		return
		
	# Swing Tool (Space bar, Left Click or action interact/ui_accept)
	if event.is_action_pressed("ui_accept") or event.is_action_pressed("interact") or (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT):
		swing_tool()
		get_viewport().set_input_as_handled()
		return

func toggle_journal() -> void:
	if Global.current_state == Global.State.OVERWORLD:
		Global.current_state = Global.State.JOURNAL
		Global.journal_toggled.emit(true)
		Global.play_sfx.emit("book_open")
	elif Global.current_state == Global.State.JOURNAL:
		Global.current_state = Global.State.OVERWORLD
		Global.journal_toggled.emit(false)
		Global.play_sfx.emit("book_close")
