extends Area2D

@export var relic_id: String = "stone_1"
@export var relic_name: String = "Relic"
@export var symbol_char: String = "ha" # From Hanacaraka (ha, na, ca, ra, ka)

@onready var visual: Node2D = $Visual
@onready var prompt: Node2D = $Prompt

var player_near = false
var is_cleaned = false

# Preload StoneBlock to spawn after cleaning
const STONE_BLOCK_SCENE = preload("res://src/entities/stone_block/stone_block.tscn")

func _ready() -> void:
	# Enable Y-sorting for cozy depth sorting
	y_sort_enabled = true
	
	collision_layer = 8 # Layer 4 (Interactables)
	collision_mask = 2 # Detect Player
	body_entered.connect(_on_player_entered)
	body_exited.connect(_on_player_exited)
	prompt.visible = false
	
	# Assign baked sprite texture or load Nesya's new assets from preloaded cache
	var sprite = Sprite2D.new()
	var tex_mound = Global.textures.get("gundukan_1")
	if tex_mound:
		sprite.texture = tex_mound
		sprite.centered = true
		sprite.offset = Vector2(0, -128)
		sprite.scale = Vector2(0.45, 0.45)
	else:
		sprite.texture = Global.get_texture("dirt_mound")
	visual.add_child(sprite)
	visual.set_script(null)
	
	# If already discovered globally, destroy this mound and spawn the stone block
	if relic_id in Global.discovered_symbols:
		call_deferred("spawn_stone_block")
		queue_free()

func _on_player_entered(body: Node2D) -> void:
	if is_cleaned: return
	if body.name == "Player":
		player_near = true
		prompt.visible = true
		# bounce prompt animation
		var tween = create_tween()
		prompt.scale = Vector2.ZERO
		tween.tween_property(prompt, "scale", Vector2.ONE, 0.15).set_trans(Tween.TRANS_BACK)

func _on_player_exited(body: Node2D) -> void:
	if body.name == "Player":
		player_near = false
		var tween = create_tween()
		tween.tween_property(prompt, "scale", Vector2.ZERO, 0.1).set_trans(Tween.TRANS_SINE)
		tween.tween_callback(func(): prompt.visible = false)

func interact(_player: CharacterBody2D) -> void:
	if is_cleaned: return
	# Switch to excavation game state
	Global.change_state(Global.State.EXCAVATION)
	Global.excavation_started.emit(self)
	prompt.visible = false
	Global.play_sfx.emit("zoom")

func complete_cleaning() -> void:
	is_cleaned = true
	var translation = ""
	if Global.dictionary.has(relic_id):
		translation = Global.dictionary[relic_id]["translation"]
	
	# Add to discovered list if not already there
	if not relic_id in Global.discovered_symbols:
		Global.discovered_symbols.append(relic_id)
		
	Global.excavation_completed.emit(relic_id, relic_name, symbol_char, translation)
	
	# Spawn dust/dirt particle burst
	Global.camera_shake.emit(3.0, 0.3)
	Global.play_sfx.emit("relic_uncovered")
	
	# Spawn the physics-based stone block and delete mound
	spawn_stone_block()
	queue_free()

func spawn_stone_block() -> void:
	var stone = STONE_BLOCK_SCENE.instantiate()
	stone.position = position
	stone.relic_id = relic_id
	stone.symbol_char = symbol_char
	stone.relic_name = relic_name
	
	# Spawn in the level parent (same parent as dirt mound)
	get_parent().add_child(stone)
