extends Node2D

@onready var excavation_overlay = $ExcavationOverlay
@onready var journal_ui = $JournalUI
@onready var ui_flash_layer = $UIFlash
@onready var ui_flash = $UIFlash/ColorRect
@onready var victory_ui = $VictoryUI
@onready var photo_frame = $VictoryUI/Control/PolaroidFrame
@onready var sfx_players = $SFXPlayers

# Preload scenes
const PLAYER_SCENE = preload("res://src/entities/player/player.tscn")
const LEVEL_1_SCENE = preload("res://src/levels/level_1.tscn")

var current_level: Node2D = null
var player: CharacterBody2D = null

func _ready() -> void:
	# Hide overlays initially
	ui_flash.color = Color(1, 1, 1, 0)
	ui_flash_layer.visible = false
	victory_ui.visible = false
	
	# Dynamically instantiate texture baker
	var baker = Node.new()
	baker.set_script(preload("res://src/core/texture_baker.gd"))
	add_child(baker)
	await baker.bake_all_textures()
	baker.queue_free()
	
	# Load level 1
	load_level()
	
	# Connect signals
	Global.play_sfx.connect(play_sound)
	Global.level_restored.connect(on_level_restored)
	
	# Play welcome sound
	Global.play_sfx.emit("welcome")

func load_level() -> void:
	if current_level:
		current_level.queue_free()
		
	# Instantiate Level
	current_level = LEVEL_1_SCENE.instantiate()
	add_child(current_level)
	# Move level behind UI layers
	move_child(current_level, 0)
	
	# Check if Player node already exists inside the level (manually placed in Editor)
	player = current_level.get_node_or_null("Player")
	if not player:
		# Fallback: Spawn Player at Marker
		player = PLAYER_SCENE.instantiate()
		var spawn_pos = Vector2(640, 640)
		if current_level.has_node("PlayerSpawn"):
			spawn_pos = current_level.get_node("PlayerSpawn").global_position
		player.position = spawn_pos
		current_level.add_child(player)

func on_level_restored() -> void:
	# Lock player movement by changing state
	Global.change_state(Global.State.JOURNAL)
	
	# 1. Screen flash effect
	ui_flash_layer.visible = true
	ui_flash.color = Color(1, 1, 1, 1)
	
	var tween = create_tween()
	tween.tween_property(ui_flash, "color", Color(1, 1, 1, 0), 0.8)
	tween.tween_callback(func(): ui_flash_layer.visible = false)
	
	# 2. Wait a bit then show the victory polaroid photo!
	get_tree().create_timer(1.2).timeout.connect(func():
		show_victory_screen()
	)

func show_victory_screen() -> void:
	victory_ui.visible = true
	photo_frame.scale = Vector2.ZERO
	photo_frame.rotation = randf_range(-0.15, 0.15)
	
	var tween = create_tween()
	tween.tween_property(photo_frame, "scale", Vector2.ONE, 0.4).set_trans(Tween.TRANS_BACK)
	Global.play_sfx.emit("camera_snap")

func restart_game() -> void:
	victory_ui.visible = false
	Global.discovered_symbols.clear()
	Global.deciphered_symbols.clear()
	Global.solved_sockets.clear()
	Global.change_state(Global.State.OVERWORLD)
	load_level()
	Global.play_sfx.emit("welcome")

# Audio playing module (with fallback logging)
func play_sound(sfx_name: String) -> void:
	# List of possible audio players
	# Find an idle player
	var player_found = null
	for p in sfx_players.get_children():
		if p is AudioStreamPlayer and not p.playing:
			player_found = p
			break
			
	if player_found == null:
		# Create a new dynamic stream player
		player_found = AudioStreamPlayer.new()
		sfx_players.add_child(player_found)
		
	# Try to load the corresponding wav asset from res://assets/audio/sfx/
	# Fallback to visual feedback and print console log if audio file is not present
	var path = "res://assets/audio/sfx/" + sfx_name + ".wav"
	if ResourceLoader.exists(path):
		player_found.stream = load(path)
		player_found.play()
	else:
		# No audio file? No problem! Fallback gracefully and print log
		print("[SFX Playback Fallback] Sound triggered: ", sfx_name)
		
		# Propose simple procedural sound synthesis if desired
		# Since it's a web-focused game, keeping it error-free is high priority.
