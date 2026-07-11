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

	# If running this level scene directly (F6 standalone test mode)
	if get_tree().current_scene == self:
		print("[Level Base] Running in F6 standalone test mode. Initializing Texture Baker...")
		var baker_script = load("res://src/core/texture_baker.gd")
		if baker_script:
			var baker = baker_script.new()
			add_child(baker)
			await baker.bake_all_textures()
			baker.queue_free()
			Global.is_baked = true
			Global.baking_completed.emit()
			print("[Level Base] Texture baking complete for F6 standalone mode!")
			
		print("[Level Base] Running in F6 standalone test mode. Spawning UI overlays dynamically.")
		
		# 1. Spawn SFX player node and connect sfx signals
		var sfx_node = Node.new()
		sfx_node.name = "SFXPlayers"
		add_child(sfx_node)
		Global.play_sfx.connect(func(sfx_name: String):
			var player_found = null
			for p in sfx_node.get_children():
				if p is AudioStreamPlayer and not p.playing:
					player_found = p
					break
			if not player_found:
				player_found = AudioStreamPlayer.new()
				sfx_node.add_child(player_found)
				
			var path = "res://assets/audio/sfx/" + sfx_name + ".wav"
			if ResourceLoader.exists(path):
				player_found.stream = load(path)
				player_found.play()
			else:
				print("[SFX Standalone Fallback] Sound triggered: ", sfx_name)
		)
		
		# 2. Spawn Excavation Overlay
		var exc_scene = load("res://src/ui/excavation/excavation_overlay.tscn")
		if exc_scene:
			var exc_ui = exc_scene.instantiate()
			add_child(exc_ui)
			
		# 3. Spawn Journal UI
		var jrn_scene = load("res://src/ui/journal/journal_ui.tscn")
		if jrn_scene:
			var jrn_ui = jrn_scene.instantiate()
			add_child(jrn_ui)

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
