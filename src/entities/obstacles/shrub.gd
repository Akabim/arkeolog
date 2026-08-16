extends StaticBody2D

@export var required_tool: Global.ToolType = Global.ToolType.SCYTHE
@export var max_health: int = 2
var health: int = max_health

@onready var visual: Node2D = $Visual
@onready var collision_shape: CollisionShape2D = get_node_or_null("CollisionShape2D") as CollisionShape2D

var shake_amount: float = 0.0
var leaves: Array = []
var is_destroyed: bool = false

@onready var player_detector: Area2D = $PlayerDetector
@onready var click_detector: Area2D = $ClickDetector

var is_player_in_range: bool = false
var is_mouse_hovering: bool = false

func _ready() -> void:
	# Enable Y-sorting for cozy depth sorting
	y_sort_enabled = true
	
	# Initialize health
	health = max_health
	
	if player_detector:
		player_detector.body_entered.connect(_on_player_entered)
		player_detector.body_exited.connect(_on_player_exited)
	
	if click_detector:
		click_detector.mouse_entered.connect(_on_mouse_entered)
		click_detector.mouse_exited.connect(_on_mouse_exited)
		click_detector.input_event.connect(_on_input_event)
	
	setup_visual()
	apply_wind_shader()
	queue_redraw()

func setup_visual() -> void:
	var tex_1: Texture2D = Global.get_texture("semak_1")
	var tex_2: Texture2D = Global.get_texture("semak_2")
	var sprite: Sprite2D = visual.get_node_or_null("Sprite2D") as Sprite2D
	if not sprite:
		sprite = Sprite2D.new()
		sprite.name = "Sprite2D"
		sprite.scale = Vector2(0.18, 0.18)
		sprite.offset = Vector2(0, -200)
		visual.add_child(sprite)
	
	if tex_1 and tex_2:
		sprite.texture = tex_1 if randf() > 0.5 else tex_2
	sprite.position = Vector2.ZERO
	visual.set_script(null) # Remove vector fallback drawing

func apply_wind_shader() -> void:
	var sprite: Sprite2D = visual.get_node_or_null("Sprite2D") as Sprite2D
	if sprite:
		var mat: ShaderMaterial = ShaderMaterial.new()
		mat.shader = preload("res://src/entities/obstacles/wind_sway.gdshader")
		mat.set_shader_parameter("sway_offset", randf() * 6.28)
		sprite.material = mat

func _process(delta: float) -> void:
	if shake_amount > 0.1:
		visual.position = Vector2(randf_range(-shake_amount, shake_amount), randf_range(-shake_amount, shake_amount))
		shake_amount = lerp(shake_amount, 0.0, 10.0 * delta)
	else:
		visual.position = Vector2.ZERO
		
	if not leaves.is_empty():
		for leaf in leaves:
			leaf.pos += leaf.vel * delta
			leaf.vel.y += 200.0 * delta # gravity
			leaf.rot += leaf.rot_vel * delta
			leaf.life -= delta
		
		leaves = leaves.filter(func(l: Dictionary) -> bool: return l.life > 0.0)
		queue_redraw()
		
		if is_destroyed and leaves.is_empty():
			queue_free()

func _on_player_entered(body: Node2D) -> void:
	if body is CharacterBody2D:
		is_player_in_range = true
		_update_highlight()

func _on_player_exited(body: Node2D) -> void:
	if body is CharacterBody2D:
		is_player_in_range = false
		_update_highlight()

func _on_mouse_entered() -> void:
	is_mouse_hovering = true
	Global.set_contextual_cursor(required_tool)
	_update_highlight()

func _on_mouse_exited() -> void:
	is_mouse_hovering = false
	Global.reset_cursor()
	_update_highlight()

func _update_highlight() -> void:
	if is_destroyed:
		_reset_cursor_and_highlight()
		return
		
	if is_player_in_range and is_mouse_hovering:
		visual.modulate = Color(1.6, 1.6, 1.6, 1.0) # White highlight
	else:
		_reset_cursor_and_highlight()

func _reset_cursor_and_highlight() -> void:
	visual.modulate = Color.WHITE

func _unhandled_input(event: InputEvent) -> void:
	if is_destroyed: return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if is_player_in_range and is_mouse_hovering:
			get_viewport().set_input_as_handled()
			_cut_shrub()

func _on_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if is_destroyed:
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if is_player_in_range:
			_cut_shrub()

func _cut_shrub() -> void:
	var players: Array[Node] = get_tree().get_nodes_in_group("player")
	var player_node: Node = players[0] if players.size() > 0 else null
	if player_node and player_node.has_method("swing_tool"):
		player_node.set("current_tool", "scythe")
		if player_node.has_method("update_tool_visual"):
			player_node.call("update_tool_visual")
		player_node.call("swing_tool")
		var player_2d: Node2D = player_node as Node2D
		var dir: Vector2 = (global_position - player_2d.global_position).normalized() if player_2d else Vector2.UP
		take_damage(1, dir)
	else:
		take_damage(1, Vector2.UP)

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
		var angle: float = direction.angle() + randf_range(-PI/4, PI/4)
		var speed: float = randf_range(80.0, 180.0)
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
	is_mouse_hovering = false
	is_player_in_range = false
	Global.reset_cursor()
	_reset_cursor_and_highlight()
	if collision_shape:
		collision_shape.set_deferred("disabled", true)
	if player_detector and player_detector.has_node("CollisionShape2D"):
		player_detector.get_node("CollisionShape2D").set_deferred("disabled", true)
	if click_detector and click_detector.has_node("CollisionShape2D"):
		click_detector.get_node("CollisionShape2D").set_deferred("disabled", true)
	visual.visible = false
	# Spawn final burst of leaf particles
	spawn_leaves(15, Vector2.UP)
	Global.play_sfx.emit("shrub_destroy")
	Global.camera_shake.emit(2.0, 0.2)

func _draw() -> void:
	# Draw leaf particles
	for leaf in leaves:
		var points: PackedVector2Array = PackedVector2Array([
			leaf.pos + Vector2(-leaf.size, 0).rotated(leaf.rot),
			leaf.pos + Vector2(0, -leaf.size * 1.5).rotated(leaf.rot),
			leaf.pos + Vector2(leaf.size, 0).rotated(leaf.rot),
			leaf.pos + Vector2(0, leaf.size * 0.5).rotated(leaf.rot),
			leaf.pos + Vector2(-leaf.size, 0).rotated(leaf.rot) # close polygon
		])
		draw_colored_polygon(points, leaf.color)
		draw_polyline(points, Global.COLOR_INK, 1.0)
