extends Node2D

@export var is_lit: bool = false
@onready var visual: Node2D = $Visual

var flicker_timer: float = 0.0

var sprite: Sprite2D = null
var anim_frame: int = 0

func _ready() -> void:
	# Add Sprite2D for baked texture rendering
	sprite = Sprite2D.new()
	sprite.name = "Sprite"
	visual.add_child(sprite)
	
	update_torch_visual()

func light_up() -> void:
	if not is_lit:
		is_lit = true
		update_torch_visual()
		# Spawn small flame particles
		Global.play_sfx.emit("torch_light")

# Suppress standard canvas drawing since we render via Sprite2D
func _draw() -> void:
	pass

func _process(delta: float) -> void:
	if is_lit:
		flicker_timer += delta
		if flicker_timer >= 0.08: # ~12 FPS
			flicker_timer = 0.0
			anim_frame = 1 - anim_frame
			update_torch_visual()

func update_torch_visual() -> void:
	if not sprite: return
	
	if not is_lit:
		if Global.textures.has("torch_off"):
			sprite.texture = Global.textures["torch_off"]
	else:
		var tex_key = "torch_on1" if anim_frame == 0 else "torch_on2"
		if Global.textures.has(tex_key):
			sprite.texture = Global.textures[tex_key]

