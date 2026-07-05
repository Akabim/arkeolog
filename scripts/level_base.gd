extends Node2D

@onready var sockets_container: Node2D = $Sockets
@onready var Player_spawn: Marker2D = $PlayerSpawn

var level_is_restored = false

func _ready() -> void:
	# Calculate total sockets in this level
	if sockets_container:
		Global.total_sockets_in_level = sockets_container.get_child_count()
	else:
		Global.total_sockets_in_level = 0
		
	Global.solved_sockets.clear()
	Global.level_restored.connect(_on_level_restored)

func _on_level_restored() -> void:
	if level_is_restored: return
	level_is_restored = true
	
	# Play awesome feedback loops
	Global.play_sfx.emit("level_clear")
	Global.camera_shake.emit(4.0, 0.6)
	
	# Light up all torches in the level
	if has_node("Torches"):
		for torch in $Torches.get_children():
			if torch.has_method("light_up"):
				torch.light_up()
				
	# Enable secret pathways or water flows (e.g. make a hidden wall disappear or reveal water)
	if has_node("RestorationVisuals"):
		$RestorationVisuals.visible = true
		
	# Trigger a flash of light / photo snapshot (handled by Main node)
	# Main node will show the photo album or success popup
