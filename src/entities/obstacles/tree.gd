extends StaticBody2D

@onready var visual: Node2D = $Visual

func _ready() -> void:
	# Enable Y-sorting on this node
	y_sort_enabled = true
	
	# If a tree texture exists in assets, use it. Otherwise, fallback to vector drawing.
	var tree_tex = Global.textures.get("tree")
	if tree_tex:
		var sprite = Sprite2D.new()
		sprite.texture = tree_tex
		sprite.offset = Vector2(0, -16)
		visual.add_child(sprite)
		visual.set_script(null)
