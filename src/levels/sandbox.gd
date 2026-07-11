extends "res://src/core/level_base.gd"

@export var level_width: float = 1280.0
@export var level_height: float = 720.0

func _ready() -> void:
	# Enable Y-Sorting for depth layering
	y_sort_enabled = true
	
	# Call base class ready to automatically discover sockets and setup camera limits
	super._ready()
