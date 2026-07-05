extends CharacterBody2D

@export var speed: float = 160.0
@export var acceleration: float = 1000.0
@export var friction: float = 800.0
@export var push_force: float = 80.0

@onready var visual: Node2D = $Visual
@onready var interaction_detector: Area2D = $InteractionDetector

var target_scale: Vector2 = Vector2.ONE
var walk_cycle: float = 0.0

var shake_intensity: float = 0.0
var shake_timer: float = 0.0

# Hands and Tool parameters
var current_tool: String = "scythe" # "scythe" or "shovel"
var hand_l: Sprite2D = null
var hand_r: Sprite2D = null
var tool_sprite: Sprite2D = null

var is_swinging: bool = false
var swing_timer: float = 0.0

func _ready() -> void:
	# Enable Y-sorting for cozy depth sorting
	y_sort_enabled = true
	
	# Enable physics interpolation if available
	if has_method("set_physics_interpolation_mode"):
		set_physics_interpolation_mode(1) # Inherit
	Global.camera_shake.connect(start_camera_shake)
	call_deferred("setup_camera_limits")
	
	# Assign baked sprite texture
	if Global.textures.has("player"):
		var sprite = Sprite2D.new()
		sprite.texture = Global.textures["player"]
		visual.add_child(sprite)
		visual.set_script(null)
		
		# Set up hands
		hand_l = Sprite2D.new()
		hand_l.name = "HandL"
		hand_l.texture = Global.textures["hand"]
		hand_l.position = Vector2(-22, 12)
		visual.add_child(hand_l)
		
		hand_r = Sprite2D.new()
		hand_r.name = "HandR"
		hand_r.texture = Global.textures["hand"]
		hand_r.position = Vector2(22, 12)
		visual.add_child(hand_r)
		
		# Set up tool attached to Hand Right
		tool_sprite = Sprite2D.new()
		tool_sprite.name = "Tool"
		tool_sprite.position = Vector2(4, -8)
		tool_sprite.rotation_degrees = -30
		hand_r.add_child(tool_sprite)
		
		update_tool_visual()

func update_tool_visual() -> void:
	if not tool_sprite: return
	if current_tool == "scythe":
		tool_sprite.texture = Global.textures["scythe"]
		tool_sprite.offset = Vector2(0, -12)
	elif current_tool == "shovel":
		tool_sprite.texture = Global.textures["shovel"]
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
			
	animate_hands(delta)

func animate_hands(delta: float) -> void:
	if not hand_l or not hand_r: return
	
	if is_swinging:
		swing_timer -= delta
		if swing_timer <= 0:
			is_swinging = false
			# Reset hand & tool positions
			hand_l.position = Vector2(-22, 12)
			hand_r.position = Vector2(22, 12)
			hand_r.rotation = 0.0
		else:
			# Calculate swing progress (0.0 to 1.0)
			var t = (0.2 - swing_timer) / 0.2
			# Swing the right hand forward and rotate the tool!
			var swing_angle = lerp(-0.5, 1.5, t) # Swing angle in radians
			hand_r.rotation = swing_angle
			hand_r.position = Vector2(22 + sin(t * PI) * 16, 12 - sin(t * PI) * 8)
			
			# Left hand does a small counter-balance move
			hand_l.position = Vector2(-22 - sin(t * PI) * 4, 12 + sin(t * PI) * 4)
	else:
		# Standard walking/idle bobbing
		if velocity.length() > 10.0:
			# Walk cycle bobbing
			hand_l.position.y = 12 + sin(walk_cycle) * 4
			hand_r.position.y = 12 - sin(walk_cycle) * 4
			hand_l.position.x = -22 + cos(walk_cycle) * 2
			hand_r.position.x = 22 - cos(walk_cycle) * 2
			hand_r.rotation = 0.0
		else:
			# Idle breathing bobbing
			var breathe = sin(Time.get_ticks_msec() * 0.004)
			hand_l.position.y = 12 + breathe * 1.5
			hand_r.position.y = 12 + breathe * 1.5
			hand_l.position.x = -22
			hand_r.position.x = 22
			hand_r.rotation = 0.0

func swing_tool() -> void:
	if is_swinging or Global.current_state != Global.State.OVERWORLD: return
	is_swinging = true
	swing_timer = 0.2 # 200 ms animation
	
	# Play dynamic sound based on tool
	if current_tool == "scythe":
		Global.play_sfx.emit("slash") # Sabit slash sound
	else:
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
		animate_idle(delta)
		return
	
	# Get input direction
	var input_dir := Vector2.ZERO
	input_dir.x = Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
	input_dir.y = Input.get_action_strength("move_down") - Input.get_action_strength("move_up")
	input_dir = input_dir.normalized()
	
	# Apply velocity
	if input_dir != Vector2.ZERO:
		velocity = velocity.move_toward(input_dir * speed, acceleration * delta)
		
		# Animate walking (bobbing/squish)
		walk_cycle += delta * 12.0
		var bob = sin(walk_cycle) * 0.08
		var stretch = cos(walk_cycle) * 0.05
		visual.scale = Vector2(1.0 + stretch, 1.0 - stretch + bob)
		
		# Face moving direction (flip visual horizontal scale)
		if input_dir.x != 0:
			visual.scale.x = (1.0 + stretch) * sign(input_dir.x)
	else:
		velocity = velocity.move_toward(Vector2.ZERO, friction * delta)
		animate_idle(delta)
	
	move_and_slide()
	
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

func animate_idle(delta: float) -> void:
	walk_cycle = 0.0
	var breathe = sin(Time.get_ticks_msec() * 0.004) * 0.03
	visual.scale = visual.scale.lerp(Vector2(1.0 + breathe, 1.0 - breathe), 10.0 * delta)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("journal"):
		toggle_journal()
		get_viewport().set_input_as_handled()
		return
		
	if Global.current_state != Global.State.OVERWORLD:
		return
		
	# Select Scythe (Key 1 or select_scythe action)
	if event.is_action_pressed("select_scythe") or (event is InputEventKey and event.pressed and event.keycode == KEY_1):
		if current_tool != "scythe":
			current_tool = "scythe"
			update_tool_visual()
			Global.play_sfx.emit("stone_scrape")
		get_viewport().set_input_as_handled()
		return
		
	# Select Shovel (Key 2 or select_shovel action)
	if event.is_action_pressed("select_shovel") or (event is InputEventKey and event.pressed and event.keycode == KEY_2):
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
