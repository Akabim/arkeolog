extends StaticBody2D

@onready var visual: Node2D = $Visual

func _ready() -> void:
	# Enable Y-sorting on this node
	y_sort_enabled = true
	
	# Instantiate sprite with baked texture
	var sprite = Sprite2D.new()
	sprite.texture = Global.get_texture("tree")
	# Center of tree is at (0,0), foliage is offset upwards, trunk is offset downwards
	# Offset sprite to sit correctly relative to physics collision
	sprite.offset = Vector2(0, -16)
	visual.add_child(sprite)
	visual.set_script(null)
