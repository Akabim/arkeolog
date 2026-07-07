extends Node2D

var sockets_container: Node2D = null
var player_spawn: Marker2D = null

var level_is_restored = false

func _ready() -> void:
	# Resolve nodes dynamically since level elements are spawned programmatically in inherited classes before super._ready()
	if has_node("Sockets"):
		sockets_container = $Sockets
	if has_node("PlayerSpawn"):
		player_spawn = $PlayerSpawn
		
	# Prevent background ColorRect from swallowing mouse click inputs
	var bg = get_node_or_null("Background")
	if bg and bg is Control:
		bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
		
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
