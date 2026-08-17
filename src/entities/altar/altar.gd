class_name Altar
extends Area2D

signal restoration_requested(puzzle_data: RestorationPuzzleData)

@export var puzzle_data: RestorationPuzzleData = null
@export var timeline_incomplete: String = "altar_incomplete"

@onready var visual: Node2D = get_node_or_null("Visual")
@onready var prompt: Node2D = get_node_or_null("Prompt")

var player_near: bool = false
var current_player: CharacterBody2D = null
var inventory: Node = null

func _ready() -> void:
	y_sort_enabled = true
	collision_layer = 8 # Layer 4 (Interactables)
	collision_mask = 2 # Detect Player (Layer 2)
	
	body_entered.connect(_on_player_entered)
	body_exited.connect(_on_player_exited)
	
	if prompt:
		prompt.visible = false
		if prompt.has_method("set_prompt_type"):
			prompt.set_prompt_type("click")

func _get_global() -> Node:
	if is_inside_tree() and has_node("/root/Global"):
		return get_node("/root/Global")
	return null

func _is_overworld() -> bool:
	var glob = _get_global()
	if glob:
		return glob.current_state == glob.State.OVERWORLD
	return true

func _play_sfx(sfx_name: String) -> void:
	var glob = _get_global()
	if glob and glob.has_signal("play_sfx"):
		glob.play_sfx.emit(sfx_name)

func _get_inventory() -> Node:
	if inventory:
		return inventory
	if is_inside_tree() and has_node("/root/InventoryManager"):
		return get_node("/root/InventoryManager")
	return null

func _on_player_entered(body: Node2D) -> void:
	if body.name == "Player" or body.is_in_group("player"):
		player_near = true
		current_player = body as CharacterBody2D
		if prompt:
			prompt.visible = true
			var tween: Tween = create_tween()
			prompt.scale = Vector2.ZERO
			tween.tween_property(prompt, "scale", Vector2.ONE, 0.15).set_trans(Tween.TRANS_BACK)

func _on_player_exited(body: Node2D) -> void:
	if body.name == "Player" or body.is_in_group("player"):
		player_near = false
		current_player = null
		if prompt:
			var tween: Tween = create_tween()
			tween.tween_property(prompt, "scale", Vector2.ZERO, 0.1).set_trans(Tween.TRANS_SINE)
			tween.tween_callback(func() -> void: prompt.visible = false)

func _unhandled_input(event: InputEvent) -> void:
	if not player_near:
		return
	if not _is_overworld():
		return
	if event.is_action_pressed("interact") or event.is_action_pressed("ui_accept"):
		interact()
		get_viewport().set_input_as_handled()

func check_completeness() -> Dictionary:
	if not puzzle_data or puzzle_data.pieces.is_empty():
		return {
			"owned": 0,
			"total": 0,
			"is_complete": false
		}
	
	var inv = _get_inventory()
	var total: int = puzzle_data.pieces.size()
	var owned: int = 0
	for piece in puzzle_data.pieces:
		if piece and inv and inv.has_method("has_fragment") and inv.has_fragment(piece.piece_id):
			owned += 1
			
	return {
		"owned": owned,
		"total": total,
		"is_complete": (owned == total and total > 0)
	}

func interact() -> void:
	if not _is_overworld():
		return
		
	var status: Dictionary = check_completeness()
	if status.is_complete:
		_play_sfx("welcome")
		restoration_requested.emit(puzzle_data)
	else:
		_trigger_incomplete_dialogue(status)

func _trigger_incomplete_dialogue(status: Dictionary) -> void:
	_play_sfx("hover")
	if is_inside_tree() and has_node("/root/Dialogic"):
		var dialogic_node = get_node("/root/Dialogic")
		if dialogic_node and dialogic_node.has_method("start"):
			dialogic_node.call("start", timeline_incomplete)
			return
	print("[Altar] Incomplete fragments: %d/%d" % [status.owned, status.total])
