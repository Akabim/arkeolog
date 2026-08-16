extends StaticBody2D

@onready var visual: Node2D = $Visual

func _ready() -> void:
	y_sort_enabled = true
	setup_visual()
	apply_wind_shader()
	queue_redraw()

func setup_visual() -> void:
	var sprite: Sprite2D = visual.get_node_or_null("Sprite2D") as Sprite2D
	if not sprite:
		sprite = Sprite2D.new()
		sprite.name = "Sprite2D"
		visual.add_child(sprite)
	# Only set texture if not already assigned in editor
	if not sprite.texture:
		var tex = Global.get_texture("pohon_1")
		if tex:
			sprite.texture = tex
	visual.set_script(null)

func apply_wind_shader() -> void:
	var sprite = visual.get_node_or_null("Sprite2D")
	if sprite:
		var mat = ShaderMaterial.new()
		mat.shader = preload("res://src/entities/obstacles/wind_sway.gdshader")
		mat.set_shader_parameter("sway_offset", randf() * 6.28)
		sprite.material = mat

