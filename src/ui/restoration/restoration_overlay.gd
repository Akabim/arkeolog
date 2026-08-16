class_name RestorationOverlay
extends CanvasLayer

signal restoration_finished(artifact_id: String)
signal restoration_cancelled

const PIECE_VIEW_SCENE = preload("res://src/ui/restoration/jigsaw_piece_view.tscn")

@onready var root_control: Control = $Control
@onready var background: TextureRect = $Control/Background
@onready var workspace: Control = $Control/Workspace
@onready var cloth_panel: TextureRect = $Control/Workspace/ClothPanel
@onready var silhouette_display: TextureRect = $Control/Workspace/ArtifactSilhouette
@onready var pieces_container: Control = $Control/Workspace/PiecesContainer
@onready var sparkle_particles: CPUParticles2D = $Control/FeedbackEffects/SparkleParticles
@onready var incorrect_flash: ColorRect = $Control/FeedbackEffects/IncorrectFlash

var controller: RestorationController = null
var input_handler: RestorationInputHandler = null

var piece_views: Dictionary = {} # piece_id: String -> JigsawPieceView
var _workspace_base_pos: Vector2 = Vector2.ZERO
var _shake_tween: Tween = null
var _flash_tween: Tween = null

func _ensure_nodes() -> void:
	if not root_control and has_node("Control"):
		root_control = $Control
	if not background and has_node("Control/Background"):
		background = $Control/Background
	if not workspace and has_node("Control/Workspace"):
		workspace = $Control/Workspace
	if not cloth_panel and has_node("Control/Workspace/ClothPanel"):
		cloth_panel = $Control/Workspace/ClothPanel
	if not silhouette_display and has_node("Control/Workspace/ArtifactSilhouette"):
		silhouette_display = $Control/Workspace/ArtifactSilhouette
	if not pieces_container and has_node("Control/Workspace/PiecesContainer"):
		pieces_container = $Control/Workspace/PiecesContainer
	if not sparkle_particles and has_node("Control/FeedbackEffects/SparkleParticles"):
		sparkle_particles = $Control/FeedbackEffects/SparkleParticles
	if not incorrect_flash and has_node("Control/FeedbackEffects/IncorrectFlash"):
		incorrect_flash = $Control/FeedbackEffects/IncorrectFlash
	if workspace and _workspace_base_pos == Vector2.ZERO:
		_workspace_base_pos = workspace.position

func _ready() -> void:
	_ensure_nodes()
	visible = false
	if workspace:
		_workspace_base_pos = workspace.position
		
	if root_control and not root_control.gui_input.is_connected(_on_root_gui_input):
		root_control.gui_input.connect(_on_root_gui_input)
		
	if get_tree().current_scene == self or (get_tree().current_scene and get_tree().current_scene.scene_file_path.contains("restoration_overlay")):
		_start_standalone_test()

func start_restoration(puzzle_data: RestorationPuzzleData, custom_center: Vector2 = Vector2(960, 540)) -> void:
	_ensure_nodes()
	visible = true
	_clean_up_existing()
	
	controller = RestorationController.new()
	input_handler = RestorationInputHandler.new()
	
	_connect_controller_signals()
	_connect_input_signals()
	
	controller.initialize_puzzle(puzzle_data, custom_center, true)
	
	var sizes: Dictionary = {}
	for piece_res in puzzle_data.pieces:
		if piece_res:
			var sz: Vector2 = piece_res.texture.get_size() if piece_res.texture else Vector2(100, 100)
			sizes[piece_res.piece_id] = sz
			
	input_handler.setup(controller, sizes)

func _clean_up_existing() -> void:
	_ensure_nodes()
	if pieces_container:
		for child in pieces_container.get_children():
			child.queue_free()
	piece_views.clear()
	
	if controller:
		_disconnect_controller_signals()
		controller = null
	if input_handler:
		_disconnect_input_signals()
		input_handler = null

func _connect_controller_signals() -> void:
	if not controller:
		return
	controller.puzzle_initialized.connect(_on_puzzle_initialized)
	controller.piece_moved.connect(_on_piece_moved)
	controller.piece_rotated.connect(_on_piece_rotated)
	controller.piece_placed_correct.connect(_on_piece_placed_correct)
	controller.piece_placed_incorrect.connect(_on_piece_placed_incorrect)
	controller.restoration_completed.connect(_on_restoration_completed)

func _disconnect_controller_signals() -> void:
	if not controller:
		return
	if controller.puzzle_initialized.is_connected(_on_puzzle_initialized):
		controller.puzzle_initialized.disconnect(_on_puzzle_initialized)
	if controller.piece_moved.is_connected(_on_piece_moved):
		controller.piece_moved.disconnect(_on_piece_moved)
	if controller.piece_rotated.is_connected(_on_piece_rotated):
		controller.piece_rotated.disconnect(_on_piece_rotated)
	if controller.piece_placed_correct.is_connected(_on_piece_placed_correct):
		controller.piece_placed_correct.disconnect(_on_piece_placed_correct)
	if controller.piece_placed_incorrect.is_connected(_on_piece_placed_incorrect):
		controller.piece_placed_incorrect.disconnect(_on_piece_placed_incorrect)
	if controller.restoration_completed.is_connected(_on_restoration_completed):
		controller.restoration_completed.disconnect(_on_restoration_completed)

func _connect_input_signals() -> void:
	if not input_handler:
		return
	input_handler.piece_hover_changed.connect(_on_piece_hover_changed)
	input_handler.drag_started.connect(_on_drag_started)
	input_handler.drag_ended.connect(_on_drag_ended)

func _disconnect_input_signals() -> void:
	if not input_handler:
		return
	if input_handler.piece_hover_changed.is_connected(_on_piece_hover_changed):
		input_handler.piece_hover_changed.disconnect(_on_piece_hover_changed)
	if input_handler.drag_started.is_connected(_on_drag_started):
		input_handler.drag_started.disconnect(_on_drag_started)
	if input_handler.drag_ended.is_connected(_on_drag_ended):
		input_handler.drag_ended.disconnect(_on_drag_ended)

func _on_root_gui_input(event: InputEvent) -> void:
	if not visible or not input_handler or not root_control:
		return
	var local_pos: Vector2 = root_control.get_local_mouse_position()
	input_handler.handle_gui_input(event, local_pos)

func _unhandled_input(event: InputEvent) -> void:
	if not visible or not input_handler:
		return
	input_handler.handle_key_input(event)

func _on_puzzle_initialized(data: RestorationPuzzleData) -> void:
	_ensure_nodes()
	if silhouette_display and data:
		silhouette_display.texture = data.silhouette_texture
		silhouette_display.visible = (data.silhouette_texture != null)
		
	for state in controller.get_all_piece_states():
		var piece_res: JigsawPieceData = state.piece_data
		var piece_id: String = state.get_piece_id()
		
		var view: JigsawPieceView = PIECE_VIEW_SCENE.instantiate() as JigsawPieceView
		if pieces_container:
			pieces_container.add_child(view)
		view.setup(
			piece_id,
			piece_res.texture if piece_res else null,
			state.current_position,
			state.get_rotation_degrees()
		)
		if state.is_locked:
			view.set_locked(true)
		piece_views[piece_id] = view

func _on_piece_moved(piece_id: String, new_pos: Vector2) -> void:
	var view: JigsawPieceView = piece_views.get(piece_id, null)
	if view:
		view.set_visual_position(new_pos)

func _on_piece_rotated(piece_id: String, _step: int, degrees: float) -> void:
	var view: JigsawPieceView = piece_views.get(piece_id, null)
	if view:
		view.set_visual_rotation(degrees)

func _on_piece_hover_changed(piece_id: String, is_hovered: bool) -> void:
	var view: JigsawPieceView = piece_views.get(piece_id, null)
	if view:
		view.set_hovered(is_hovered)

func _on_drag_started(piece_id: String) -> void:
	var view: JigsawPieceView = piece_views.get(piece_id, null)
	if view:
		view.move_to_front()
		view.z_index = 10

func _on_drag_ended(piece_id: String) -> void:
	var view: JigsawPieceView = piece_views.get(piece_id, null)
	if view and not controller.is_piece_locked(piece_id):
		view.z_index = 1

func _on_piece_placed_correct(piece_id: String, snapped_pos: Vector2) -> void:
	var view: JigsawPieceView = piece_views.get(piece_id, null)
	if view:
		view.animate_snap(snapped_pos)

func _on_piece_placed_incorrect(piece_id: String, _curr_pos: Vector2) -> void:
	var view: JigsawPieceView = piece_views.get(piece_id, null)
	if view:
		view.animate_incorrect()
	shake_ui(6.0, 0.2)
	_flash_incorrect()

func _on_restoration_completed(artifact_id: String) -> void:
	if sparkle_particles:
		sparkle_particles.position = controller.artifact_center
		sparkle_particles.restart()
	restoration_finished.emit(artifact_id)

func shake_ui(intensity: float, duration: float) -> void:
	_ensure_nodes()
	if not workspace:
		return
		
	if _shake_tween and _shake_tween.is_running():
		_shake_tween.kill()
		workspace.position = _workspace_base_pos
	else:
		_workspace_base_pos = workspace.position
		
	_shake_tween = create_tween()
	var steps: int = int(max(3, duration / 0.03))
	var step_duration: float = duration / float(steps)
	
	for i in range(steps):
		var current_intensity: float = intensity * (1.0 - float(i) / float(steps))
		var offset: Vector2 = Vector2(
			randf_range(-current_intensity, current_intensity),
			randf_range(-current_intensity, current_intensity)
		)
		_shake_tween.tween_property(workspace, "position", _workspace_base_pos + offset, step_duration)
		
	_shake_tween.tween_property(workspace, "position", _workspace_base_pos, step_duration)

func _flash_incorrect() -> void:
	_ensure_nodes()
	if not incorrect_flash:
		return
	if _flash_tween and _flash_tween.is_running():
		_flash_tween.kill()
	incorrect_flash.color = Color(1.0, 0.0, 0.0, 0.15)
	_flash_tween = create_tween()
	_flash_tween.tween_property(incorrect_flash, "color", Color(1.0, 0.0, 0.0, 0.0), 0.2)

func _start_standalone_test() -> void:
	var test_puzzle := RestorationPuzzleData.new()
	test_puzzle.artifact_id = "standalone_test_relic"
	test_puzzle.snap_tolerance = 45.0
	test_puzzle.radial_radius = 280.0
	
	var p_tex: Texture2D = load("res://assets/textures/relics/Prasasti.png")
	test_puzzle.silhouette_texture = p_tex
	
	var b1_tex: Texture2D = load("res://assets/textures/relics/Batu 1.png")
	var b2_tex: Texture2D = load("res://assets/textures/relics/Batu 2.png")
	var b3_tex: Texture2D = load("res://assets/textures/relics/Batu 3.png")
	
	var p1 := JigsawPieceData.new()
	p1.piece_id = "p1"
	p1.texture = b1_tex
	p1.target_offset = Vector2(-80.0, -50.0)
	
	var p2 := JigsawPieceData.new()
	p2.piece_id = "p2"
	p2.texture = b2_tex
	p2.target_offset = Vector2(80.0, -50.0)
	
	var p3 := JigsawPieceData.new()
	p3.piece_id = "p3"
	p3.texture = b3_tex
	p3.target_offset = Vector2(0.0, 70.0)
	
	test_puzzle.pieces = [p1, p2, p3]
	
	start_restoration(test_puzzle, Vector2(960, 540))
