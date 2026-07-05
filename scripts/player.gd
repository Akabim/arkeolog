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

func _ready() -> void:
	# Enable physics interpolation if available
	if has_method("set_physics_interpolation_mode"):
		set_physics_interpolation_mode(1) # Inherit
	Global.camera_shake.connect(start_camera_shake)

func start_camera_shake(intensity: float, duration: float) -> void:
	shake_intensity = intensity
	shake_timer = duration

func _process(delta: float) -> void:
	if shake_timer > 0.0:
		shake_timer -= delta
		$Camera2D.offset = Vector2(randf_range(-shake_intensity, shake_intensity), randf_range(-shake_intensity, shake_intensity))
		if shake_timer <= 0.0:
			$Camera2D.offset = Vector2.ZERO


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
			# Push the stone block
			var direction = -collision.get_normal()
			# Apply force at the collision point
			collider.apply_central_force(direction * push_force * 10.0)
			
			# Add a bit of screen shake when starting to push (juice!)
			if velocity.length() > 50.0 and randf() < 0.05:
				Global.camera_shake.emit(1.5, 0.1)
				Global.play_sfx.emit("push")

func animate_idle(delta: float) -> void:
	walk_cycle = 0.0
	# Smoothly return to normal scale with a breathing idle effect
	var breathe = sin(Time.get_ticks_msec() * 0.004) * 0.03
	visual.scale = visual.scale.lerp(Vector2(1.0 + breathe, 1.0 - breathe), 10.0 * delta)

func _unhandled_input(event: InputEvent) -> void:
	if Global.current_state != Global.State.OVERWORLD:
		return
		
	if event.is_action_pressed("interact"):
		interact()
	elif event.is_action_pressed("journal"):
		toggle_journal()

func interact() -> void:
	var areas = interaction_detector.get_overlapping_areas()
	for area in areas:
		var parent = area.get_parent()
		if parent and parent.has_method("interact"):
			parent.interact(self)
			break

func toggle_journal() -> void:
	if Global.current_state == Global.State.OVERWORLD:
		Global.current_state = Global.State.JOURNAL
		Global.journal_toggled.emit(true)
		Global.play_sfx.emit("book_open")
	elif Global.current_state == Global.State.JOURNAL:
		Global.current_state = Global.State.OVERWORLD
		Global.journal_toggled.emit(false)
		Global.play_sfx.emit("book_close")
