class_name RestorationController
extends RefCounted

signal puzzle_initialized(puzzle_data: RestorationPuzzleData)
signal piece_moved(piece_id: String, new_position: Vector2)
signal piece_rotated(piece_id: String, rotation_step: int, rotation_degrees: float)
signal piece_placed_correct(piece_id: String, snapped_position: Vector2)
signal piece_placed_incorrect(piece_id: String, current_position: Vector2)
signal restoration_completed(artifact_id: String)

var puzzle_data: RestorationPuzzleData
var artifact_center: Vector2 = Vector2.ZERO
var piece_states: Dictionary = {} # piece_id: String -> JigsawPieceState
var piece_order: Array[String] = []
var locked_piece_count: int = 0
var is_completed: bool = false

# Calculation helpers (Deterministic)
static func calculate_radial_position(center: Vector2, index: int, total_count: int, radius: float) -> Vector2:
	if total_count <= 0:
		return center
	var angle: float = (float(index) * TAU / float(total_count)) - (PI / 2.0)
	return center + Vector2.from_angle(angle) * radius

static func calculate_target_position(center: Vector2, offset: Vector2) -> Vector2:
	return center + offset

static func step_to_degrees(step: int) -> float:
	return posmod(step, 4) * 90.0

static func step_to_radians(step: int) -> float:
	return posmod(step, 4) * (PI / 2.0)

# Lifecycle
func initialize_puzzle(data: RestorationPuzzleData, center: Vector2, randomize_rotation: bool = true) -> void:
	puzzle_data = data
	artifact_center = center
	piece_states.clear()
	piece_order.clear()
	locked_piece_count = 0
	is_completed = false
	
	if not puzzle_data:
		return
		
	var total_pieces: int = puzzle_data.pieces.size()
	for i in range(total_pieces):
		var piece_res: JigsawPieceData = puzzle_data.pieces[i]
		if not piece_res:
			continue
			
		var state := JigsawPieceState.new(piece_res)
		state.target_position = calculate_target_position(center, piece_res.target_offset)
		state.current_position = calculate_radial_position(center, i, total_pieces, puzzle_data.radial_radius)
		state.rotation_step = randi() % 4 if randomize_rotation else 0
		state.is_locked = false
		
		piece_states[piece_res.piece_id] = state
		piece_order.append(piece_res.piece_id)
		
	puzzle_initialized.emit(puzzle_data)

# Query API
func get_piece_state(piece_id: String) -> JigsawPieceState:
	return piece_states.get(piece_id, null)

func get_all_piece_states() -> Array[JigsawPieceState]:
	var result: Array[JigsawPieceState] = []
	for id in piece_order:
		if piece_states.has(id):
			result.append(piece_states[id])
	return result

func is_piece_locked(piece_id: String) -> bool:
	var state: JigsawPieceState = get_piece_state(piece_id)
	return state.is_locked if state else false

func is_complete() -> bool:
	return is_completed

func get_locked_count() -> int:
	return locked_piece_count

func get_total_count() -> int:
	return piece_states.size()

# Manipulation API (for Input / UI Agents)
func set_piece_position(piece_id: String, new_pos: Vector2) -> bool:
	var state: JigsawPieceState = get_piece_state(piece_id)
	if not state or state.is_locked:
		return false
	state.current_position = new_pos
	piece_moved.emit(piece_id, new_pos)
	return true

func rotate_piece(piece_id: String, clockwise: bool = true) -> bool:
	var state: JigsawPieceState = get_piece_state(piece_id)
	if not state or state.is_locked:
		return false
	var delta: int = 1 if clockwise else 3
	state.rotation_step = (state.rotation_step + delta) % 4
	piece_rotated.emit(piece_id, state.rotation_step, state.get_rotation_degrees())
	return true

func set_piece_rotation_step(piece_id: String, step: int) -> bool:
	var state: JigsawPieceState = get_piece_state(piece_id)
	if not state or state.is_locked:
		return false
	state.rotation_step = posmod(step, 4)
	piece_rotated.emit(piece_id, state.rotation_step, state.get_rotation_degrees())
	return true

func validate_placement(piece_id: String) -> bool:
	var state: JigsawPieceState = get_piece_state(piece_id)
	if not state:
		return false
	if state.is_locked:
		return true
	if not puzzle_data:
		return false
		
	var dist_ok: bool = state.current_position.distance_to(state.target_position) <= puzzle_data.snap_tolerance
	var rot_ok: bool = (state.rotation_step == 0)
	return dist_ok and rot_ok

func release_piece(piece_id: String) -> bool:
	var state: JigsawPieceState = get_piece_state(piece_id)
	if not state:
		return false
	if state.is_locked:
		return true
		
	if validate_placement(piece_id):
		state.current_position = state.target_position
		state.rotation_step = 0
		state.is_locked = true
		locked_piece_count += 1
		piece_placed_correct.emit(piece_id, state.target_position)
		
		if locked_piece_count == piece_states.size() and piece_states.size() > 0:
			is_completed = true
			restoration_completed.emit(puzzle_data.artifact_id if puzzle_data else "")
		return true
	else:
		# Incorrect placement: stays at drop position, remains unlocked
		piece_placed_incorrect.emit(piece_id, state.current_position)
		return false
