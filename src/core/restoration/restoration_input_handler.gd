class_name RestorationInputHandler
extends RefCounted

signal drag_started(piece_id: String)
signal drag_ended(piece_id: String)
signal piece_hover_changed(piece_id: String, is_hovered: bool)

var controller: RestorationController = null
var piece_sizes: Dictionary = {} # piece_id: String -> Vector2
var default_piece_size: Vector2 = Vector2(100.0, 100.0)

var held_piece_id: String = ""
var hovered_piece_id: String = ""
var drag_offset: Vector2 = Vector2.ZERO
var is_active: bool = true

func _init(p_controller: RestorationController = null, p_piece_sizes: Dictionary = {}) -> void:
	if p_controller != null:
		setup(p_controller, p_piece_sizes)

func setup(p_controller: RestorationController, p_piece_sizes: Dictionary = {}) -> void:
	controller = p_controller
	piece_sizes = p_piece_sizes.duplicate()
	held_piece_id = ""
	hovered_piece_id = ""
	drag_offset = Vector2.ZERO

func set_piece_size(piece_id: String, size: Vector2) -> void:
	piece_sizes[piece_id] = size

func get_piece_size(piece_id: String) -> Vector2:
	if piece_sizes.has(piece_id):
		return piece_sizes[piece_id]
	if controller:
		var state: JigsawPieceState = controller.get_piece_state(piece_id)
		if state and state.piece_data and state.piece_data.texture:
			return state.piece_data.texture.get_size()
	return default_piece_size

func hit_test_piece(point: Vector2) -> String:
	if not controller or not is_active:
		return ""
	
	# Reverse piece order to hit-test topmost/frontmost pieces first
	var piece_ids: Array[String] = controller.piece_order.duplicate()
	piece_ids.reverse()
	
	for piece_id in piece_ids:
		if controller.is_piece_locked(piece_id):
			continue
		
		var state: JigsawPieceState = controller.get_piece_state(piece_id)
		if not state:
			continue
		
		var size: Vector2 = get_piece_size(piece_id)
		if posmod(state.rotation_step, 2) == 1:
			size = Vector2(size.y, size.x)
		var half_size: Vector2 = size / 2.0
		var rect: Rect2 = Rect2(state.current_position - half_size, size)

		if rect.has_point(point):
			return piece_id
			
	return ""

func handle_gui_input(event: InputEvent, local_mouse_pos: Vector2) -> bool:
	if not is_active or not controller:
		return false
		
	if event is InputEventMouseButton:
		var mb: InputEventMouseButton = event as InputEventMouseButton
		
		if mb.button_index == MOUSE_BUTTON_LEFT:
			if mb.pressed:
				return _on_lmb_pressed(local_mouse_pos)
			else:
				return _on_lmb_released()
				
		elif mb.button_index == MOUSE_BUTTON_RIGHT:
			if mb.pressed:
				return rotate_held_piece()
				
	elif event is InputEventMouseMotion:
		return _on_mouse_motion(local_mouse_pos)
		
	return false

func handle_key_input(event: InputEvent) -> bool:
	if not is_active or not controller:
		return false
		
	if event is InputEventKey:
		var key_event: InputEventKey = event as InputEventKey
		if key_event.pressed and not key_event.echo:
			if key_event.physical_keycode == KEY_R or key_event.keycode == KEY_R:
				return rotate_held_piece()
				
	return false

func rotate_held_piece() -> bool:
	if held_piece_id == "" or not controller:
		return false
	if controller.is_piece_locked(held_piece_id):
		return false
	return controller.rotate_piece(held_piece_id, true)

func cancel_drag() -> void:
	if held_piece_id != "":
		var id: String = held_piece_id
		held_piece_id = ""
		drag_offset = Vector2.ZERO
		drag_ended.emit(id)

func _on_lmb_pressed(mouse_pos: Vector2) -> bool:
	var hit_id: String = hit_test_piece(mouse_pos)
	if hit_id == "":
		return false
		
	if controller.is_piece_locked(hit_id):
		return false
		
	held_piece_id = hit_id
	var state: JigsawPieceState = controller.get_piece_state(hit_id)
	if state:
		drag_offset = state.current_position - mouse_pos
	else:
		drag_offset = Vector2.ZERO
		
	drag_started.emit(held_piece_id)
	return true

func _on_lmb_released() -> bool:
	if held_piece_id == "":
		return false
		
	var id_to_release: String = held_piece_id
	held_piece_id = ""
	drag_offset = Vector2.ZERO
	
	controller.release_piece(id_to_release)
	drag_ended.emit(id_to_release)
	return true

func _on_mouse_motion(mouse_pos: Vector2) -> bool:
	if held_piece_id != "":
		var new_pos: Vector2 = mouse_pos + drag_offset
		controller.set_piece_position(held_piece_id, new_pos)
		return true
	else:
		var hit_id: String = hit_test_piece(mouse_pos)
		_update_hover(hit_id)
		return false

func _update_hover(new_hover_id: String) -> void:
	if hovered_piece_id != new_hover_id:
		if hovered_piece_id != "":
			piece_hover_changed.emit(hovered_piece_id, false)
		hovered_piece_id = new_hover_id
		if hovered_piece_id != "":
			piece_hover_changed.emit(hovered_piece_id, true)
