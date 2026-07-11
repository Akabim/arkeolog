extends CharacterBody2D

@export var speed: float = 160.0
@export var acceleration: float = 1000.0
@export var friction: float = 800.0
@export var push_force: float = 80.0

@onready var visual: Node2D = $Visual
#@onready var sprite: Sprite2D = $Visual/Sprite
@onready var hand_l: Sprite2D = $Visual/Badan/HandL
@onready var hand_r: Sprite2D = $Visual/Badan/HandR
@onready var shovel_sprite: Sprite2D = $Visual/Badan/HandL/Shovel
@onready var scythe_sprite: Sprite2D = $Visual/Badan/HandL/Scythe
@onready var pickaxe_sprite: Sprite2D = $Visual/Badan/HandL/Pickaxe
@onready var anim: AnimationPlayer = $AnimationPlayer
@onready var interaction_detector: Area2D = $InteractionDetector
@onready var dust_particles: CPUParticles2D = $DustParticles
@onready var base_scale_x: float = abs(visual.scale.x)

@onready var sprite_tas: Sprite2D = $Visual/Tas
@onready var sprite_kaki_l: Sprite2D = $Visual/KakiKiri
@onready var sprite_kaki_r: Sprite2D = $Visual/KakiKanan
@onready var sprite_badan: Sprite2D = $Visual/Badan
@onready var sprite_kepala: Sprite2D = $Visual/Kepala
@onready var sprite_topi: Sprite2D = $Visual/Topi

var current_tool: String = "scythe" # "scythe" or "shovel"

var shake_intensity: float = 0.0
var shake_timer: float = 0.0

var textures_front: Dictionary = {}
var textures_back: Dictionary = {}
var current_facing: String = "front"

func _ready() -> void:
	# Create soft radial shadow at player's feet
	var grad = Gradient.new()
	grad.colors = PackedColorArray([Color(0, 0, 0, 0.4), Color(0, 0, 0, 0)])
	grad.offsets = PackedFloat32Array([0.0, 1.0])
	
	var grad_tex = GradientTexture2D.new()
	grad_tex.gradient = grad
	grad_tex.fill = GradientTexture2D.FILL_RADIAL
	grad_tex.fill_from = Vector2(0.5, 0.5)
	grad_tex.fill_to = Vector2(0.5, 0.0)
	grad_tex.width = 64
	grad_tex.height = 64
	
	var shadow = Sprite2D.new()
	shadow.name = "Shadow"
	shadow.texture = grad_tex
	shadow.position = Vector2(-5, 46)
	shadow.scale = Vector2(1.5, 0.6)
	shadow.show_behind_parent = true
	shadow.z_index = -1
	add_child(shadow)
	move_child(shadow, 0)

	# Enable Y-sorting for cozy depth sorting
	y_sort_enabled = true
	
	# Enable physics interpolation if available
	if has_method("set_physics_interpolation_mode"):
		set_physics_interpolation_mode(1) # Inherit
	Global.camera_shake.connect(start_camera_shake)
	call_deferred("setup_camera_limits")
	
	# Load modular textures
	textures_front = {
		"tas": load("res://assets/textures/player/Char depan/Tas.png"),
		"kaki_l": load("res://assets/textures/player/Char depan/Kaki Kiri.png"),
		"kaki_r": load("res://assets/textures/player/Char depan/Kaki Kanan.png"),
		"badan": load("res://assets/textures/player/Char depan/Badan.png"),
		"kepala": load("res://assets/textures/player/Char depan/Kepala.png"),
		"topi": load("res://assets/textures/player/Char depan/Topi.png"),
		"tangan_l": load("res://assets/textures/player/Char depan/tangan kiri.png"),
		"tangan_r": load("res://assets/textures/player/Char depan/tangan kanan.png")
	}
	textures_back = {
		"tas": load("res://assets/textures/player/Char Belakang/Tas.png"),
		"kaki_l": load("res://assets/textures/player/Char Belakang/Kaki Kiri.png"),
		"kaki_r": load("res://assets/textures/player/Char Belakang/Kaki Kanan.png"),
		"badan": load("res://assets/textures/player/Char Belakang/badan.png"),
		"kepala": load("res://assets/textures/player/Char Belakang/Kepala.png"),
		"topi": load("res://assets/textures/player/Char Belakang/Topi.png"),
		"tangan_l": load("res://assets/textures/player/Char Belakang/Tangan Kiri.png"),
		"tangan_r": load("res://assets/textures/player/Char Belakang/Tangan Kanan.png")
	}
		
	update_tool_visual()

func update_tool_visual() -> void:
	if not shovel_sprite or not scythe_sprite or not pickaxe_sprite: return
	
	# Load scythe/pickaxe textures dynamically from Global if they are not already loaded
	if not scythe_sprite.texture:
		scythe_sprite.texture = Global.get_texture("scythe")
	if not pickaxe_sprite.texture:
		pickaxe_sprite.texture = Global.get_texture("pickaxe")
	if not shovel_sprite.texture:
		shovel_sprite.texture = Global.get_texture("shovel")
		
	# Hide all tools
	shovel_sprite.visible = false
	scythe_sprite.visible = false
	pickaxe_sprite.visible = false
	
	# Show active tool
	var active_sprite = get_active_tool_sprite()
	if active_sprite:
		active_sprite.visible = true

	# Update hand positions/rotations depending on equipped tool
	if hand_l and hand_r:
		if current_tool == "shovel":
			# Shovel/Scythe: Hold diagonally with 2 hands (sync with user's swing_shovel keyframe start)
			hand_l.position = Vector2(-100.195, -116.895)
			hand_r.position = Vector2(-131, -155.105)
			hand_l.rotation = 0.0
			hand_r.rotation = 0.0
		else:
			# Default (none): Hold parallel on the sides
			hand_l.position = Vector2(-124, -135)
			hand_r.position = Vector2(-131, -128)
			hand_l.rotation = 0.0
			hand_r.rotation = 0.0

	# Refresh current animation with the new tool variant
	if anim and anim.is_playing():
		var cur = anim.current_animation
		if cur.begins_with("walk") or cur.begins_with("idle"):
			var base = "walk" if cur.begins_with("walk") else "idle"
			play_anim(base)

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
	return anim.current_animation == "swing_scythe" or anim.current_animation == "swing_shovel" or anim.current_animation == "swing_pickaxe"


func swing_tool() -> void:
	if check_swinging() or Global.current_state != Global.State.OVERWORLD: return
	
	# Play animation based on tool
	if current_tool == "scythe":
		anim.play("swing_scythe")
		Global.play_sfx.emit("slash") # Sabit slash sound
	elif current_tool == "pickaxe":
		anim.play("swing_pickaxe")
		Global.play_sfx.emit("slash") # Beliung slash sound
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
			play_anim("idle")
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
			visual.scale.x = -sign(input_dir.x) * base_scale_x
			
		# Vertical facing check
		if input_dir.y < -0.1:
			set_vertical_facing("back")
		elif input_dir.y > 0.1:
			set_vertical_facing("front")
			
		if not check_swinging():
			play_anim("walk")
	else:
		velocity = velocity.move_toward(Vector2.ZERO, friction * delta)
		if not check_swinging():
			play_anim("idle")
	
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
		if current_tool == "scythe":
			current_tool = "none"
		else:
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
		if current_tool == "shovel":
			current_tool = "none"
		else:
			current_tool = "shovel"
		update_tool_visual()
		Global.play_sfx.emit("stone_scrape")
		get_viewport().set_input_as_handled()
		return
		
	# Select Pickaxe (Key 3 or select_pickaxe action)
	var is_pickaxe_pressed = (event is InputEventKey and event.pressed and event.keycode == KEY_3)
	if InputMap.has_action("select_pickaxe") and event.is_action_pressed("select_pickaxe"):
		is_pickaxe_pressed = true
		
	if is_pickaxe_pressed:
		if current_tool == "pickaxe":
			current_tool = "none"
		else:
			current_tool = "pickaxe"
		update_tool_visual()
		Global.play_sfx.emit("stone_scrape")
		get_viewport().set_input_as_handled()
		return
		
	# Swing Tool (Exclusively Mouse Left Click)
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		swing_tool()
		get_viewport().set_input_as_handled()
		return
		
	# Interact (Key E / Space or interact action)
	if event.is_action_pressed("interact") or event.is_action_pressed("ui_accept"):
		interact_with_surroundings()
		get_viewport().set_input_as_handled()
		return

func toggle_journal() -> void:
	if Global.current_state == Global.State.OVERWORLD:
		Global.change_state(Global.State.JOURNAL)
		Global.journal_toggled.emit(true)
		Global.play_sfx.emit("book_open")
	elif Global.current_state == Global.State.JOURNAL:
		Global.change_state(Global.State.OVERWORLD)
		Global.journal_toggled.emit(false)
		Global.play_sfx.emit("book_close")

func interact_with_surroundings() -> void:
	if Global.current_state != Global.State.OVERWORLD: return
	
	# Detect nearby interactable areas
	var areas = interaction_detector.get_overlapping_areas()
	for area in areas:
		var mound = area if area.has_method("interact") else area.get_parent()
		# Interact with Dirt Mound
		if mound and mound.name.begins_with("DirtMound") and mound.has_method("interact"):
			if current_tool == "shovel":
				# Dig it!
				anim.play("swing_shovel")
				Global.play_sfx.emit("dig")
				mound.interact(self)
			else:
				# Warn player they need Shovel
				print("Kamu butuh sekop untuk menggali gundukan tanah ini!")
				Global.play_sfx.emit("stone_scrape")
			return

func set_vertical_facing(facing: String) -> void:
	if current_facing == facing:
		return
	current_facing = facing
	update_character_facing()

func update_character_facing() -> void:
	var dict = textures_front if current_facing == "front" else textures_back
	
	# Safety checks
	if not sprite_tas or not sprite_kaki_l or not sprite_kaki_r or not sprite_badan or not sprite_kepala or not sprite_topi or not hand_l or not hand_r:
		return
		
	sprite_tas.texture = dict["tas"]
	sprite_kaki_l.texture = dict["kaki_l"]
	sprite_kaki_r.texture = dict["kaki_r"]
	sprite_badan.texture = dict["badan"]
	sprite_kepala.texture = dict["kepala"]
	sprite_topi.texture = dict["topi"]
	hand_l.texture = dict["tangan_l"]
	hand_r.texture = dict["tangan_r"]
	
	# Adjust Z-index of Tas and Tool:
	# Front facing: Tas is behind everything (-1), Tool is in front (0)
	# Back facing: Tas is on top of Badan (1), Tool is behind body (-2)
	var active_tool_sprite = get_active_tool_sprite()
	if current_facing == "front":
		sprite_tas.z_index = -1
		if active_tool_sprite:
			active_tool_sprite.z_index = 0
	else:
		sprite_tas.z_index = 1
		if active_tool_sprite:
			active_tool_sprite.z_index = -2

func get_active_tool_sprite() -> Sprite2D:
	if not is_inside_tree(): return null
	if current_tool == "shovel":
		return shovel_sprite
	elif current_tool == "scythe":
		return scythe_sprite
	elif current_tool == "pickaxe":
		return pickaxe_sprite
	return null

func play_anim(base_name: String) -> void:
	if not anim: return
	var anim_name = base_name
	if current_tool == "shovel":
		anim_name = base_name + "_shovel"
	elif current_tool == "scythe":
		anim_name = base_name + "_scythe"
	
	if anim.has_animation(anim_name):
		anim.play(anim_name)
	else:
		anim.play(base_name)
