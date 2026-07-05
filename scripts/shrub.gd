extends StaticBody2D

@export var max_health: int = 2
var health: int = max_health

@onready var visual: Node2D = $Visual
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

var shake_amount: float = 0.0
var leaves: Array = []
var is_destroyed = false

func _ready() -> void:
	# Initialize health
	health = max_health
	$BashDetector.body_entered.connect(_on_player_entered)

func _process(delta: float) -> void:
	if shake_amount > 0.1:
		visual.position = Vector2(randf_range(-shake_amount, shake_amount), randf_range(-shake_amount, shake_amount))
		shake_amount = lerp(shake_amount, 0.0, 10.0 * delta)
	else:
		visual.position = Vector2.ZERO
		
	# Update leaf particles if any
	if not leaves.is_empty():
		for leaf in leaves:
			leaf.pos += leaf.vel * delta
			leaf.vel.y += 200.0 * delta # gravity
			leaf.rot += leaf.rot_vel * delta
			leaf.life -= delta
		
		# Remove dead leaves
		leaves = leaves.filter(func(l): return l.life > 0.0)
		queue_redraw()
		
		if is_destroyed and leaves.is_empty():
			queue_free()

func _on_player_entered(body: Node2D) -> void:
	if is_destroyed: return
	if body is CharacterBody2D:
		# Check if player is moving with some velocity
		if body.velocity.length() > 30.0:
			take_damage(1, body.velocity.normalized())

func take_damage(amount: int, direction: Vector2) -> void:
	health -= amount
	shake_amount = 6.0
	Global.play_sfx.emit("shrub_hit")
	Global.camera_shake.emit(1.0, 0.1)
	
	# Spawn some leaf particles in the bash direction
	spawn_leaves(8, direction)
	
	if health <= 0:
		destroy()

func spawn_leaves(count: int, direction: Vector2) -> void:
	for i in range(count):
		var angle = direction.angle() + randf_range(-PI/4, PI/4)
		var speed = randf_range(80.0, 180.0)
		leaves.append({
			"pos": Vector2.ZERO,
			"vel": Vector2.from_angle(angle) * speed + Vector2(0, -50),
			"rot": randf_range(0, 2*PI),
			"rot_vel": randf_range(-10, 10),
			"color": Global.COLOR_OBSTACLES.lerp(Global.COLOR_BG_GRASS, randf()),
			"size": randf_range(3.0, 6.0),
			"life": randf_range(0.4, 0.8)
		})
	queue_redraw()

func destroy() -> void:
	is_destroyed = true
	collision_shape.set_deferred("disabled", true)
	$BashDetector/CollisionShape2D.set_deferred("disabled", true)
	visual.visible = false
	# Spawn final burst of leaf particles
	spawn_leaves(15, Vector2.UP)
	Global.play_sfx.emit("shrub_destroy")
	Global.camera_shake.emit(2.0, 0.2)

func _draw() -> void:
	# Draw leaf particles
	for leaf in leaves:
		var rot_cos = cos(leaf.rot)
		var rot_sin = sin(leaf.rot)
		var points = PackedVector2Array([
			leaf.pos + Vector2(-leaf.size, 0).rotated(leaf.rot),
			leaf.pos + Vector2(0, -leaf.size * 1.5).rotated(leaf.rot),
			leaf.pos + Vector2(leaf.size, 0).rotated(leaf.rot),
			leaf.pos + Vector2(0, leaf.size * 0.5).rotated(leaf.rot),
			leaf.pos + Vector2(-leaf.size, 0).rotated(leaf.rot) # close polygon
		])
		draw_colored_polygon(points, leaf.color)
		draw_polyline(points, Global.COLOR_INK, 1.0)

