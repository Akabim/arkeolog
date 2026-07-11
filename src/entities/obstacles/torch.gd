extends Node2D

@export var is_lit: bool = false
@onready var visual: Node2D = $Visual

var flicker_timer: float = 0.0
var sprite: Sprite2D = null

func _ready() -> void:
	var tex_off = Global.textures.get("torch_off")
	var tex_on = Global.textures.get("torch_on")
	if tex_off and tex_on:
		sprite = Sprite2D.new()
		sprite.centered = true
		sprite.offset = Vector2(0, -128)
		sprite.scale = Vector2(0.45, 0.45)
		visual.add_child(sprite)
	else:
		# Fallback to vector drawing
		var visual_script = load("res://src/entities/obstacles/torch_visual.gd")
		if visual_script:
			visual.set_script(visual_script)
			
	update_torch_visual()

func light_up() -> void:
	if not is_lit:
		is_lit = true
		update_torch_visual()
		# Spawn small flame particles
		Global.play_sfx.emit("torch_light")

func _process(delta: float) -> void:
	if is_lit:
		flicker_timer += delta
		if flicker_timer >= 0.08: # ~12 FPS
			flicker_timer = 0.0
			if not sprite:
				# Vector flicker
				visual.queue_redraw()

func update_torch_visual() -> void:
	if sprite:
		if not is_lit:
			sprite.texture = Global.textures.get("torch_off")
		else:
			sprite.texture = Global.textures.get("torch_on")
	else:
		if "is_lit" in visual:
			visual.is_lit = is_lit
			visual.queue_redraw()
