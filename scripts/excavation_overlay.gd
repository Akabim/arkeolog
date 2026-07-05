extends CanvasLayer

@onready var main_panel: Control = $Control
@onready var label_instruction: Label = $Control/InstructionLabel
@onready var btn_chisel = $Control/Tools/BtnChisel
@onready var btn_brush = $Control/Tools/BtnBrush
@onready var btn_spray = $Control/Tools/BtnSpray
@onready var btn_complete = $Control/BtnComplete
@onready var relic_view = $Control/RelicView

# Game State
enum Tool { CHISEL, BRUSH, SPRAY }
var active_tool: Tool = Tool.CHISEL

var target_mound = null
var relic_id: String = ""
var symbol_char: String = "ha"
var relic_name: String = ""

# Step States
var chisel_nodes = [] # Array of Vector2 positions for chunks
var brush_nodes = [] # Array of dict {pos: Vector2, alpha: float, size: float}
var spray_amount: float = 0.0 # From 0 to 1.0 (sprayed completeness)
var completed_steps = false

func _ready() -> void:
	visible = false
	btn_complete.visible = false
	btn_complete.pressed.connect(_on_complete_pressed)
	
	btn_chisel.pressed.connect(func(): set_tool(Tool.CHISEL))
	btn_brush.pressed.connect(func(): set_tool(Tool.BRUSH))
	btn_spray.pressed.connect(func(): set_tool(Tool.SPRAY))
	
	Global.excavation_started.connect(start_game)

func start_game(mound) -> void:
	target_mound = mound
	relic_id = mound.relic_id
	symbol_char = mound.symbol_char
	relic_name = mound.relic_name
	
	# Reset states
	active_tool = Tool.CHISEL
	completed_steps = false
	spray_amount = 0.0
	btn_complete.visible = false
	
	# Generate Chisel Chunks (Step 1)
	chisel_nodes.clear()
	chisel_nodes = [
		Vector2(120, 100),
		Vector2(200, 90),
		Vector2(140, 220),
		Vector2(210, 210)
	]
	
	# Generate Brush Dust spots (Step 2)
	brush_nodes.clear()
	for x in range(5):
		for y in range(4):
			brush_nodes.append({
				"pos": Vector2(100 + x * 35 + randf_range(-10, 10), 100 + y * 35 + randf_range(-10, 10)),
				"alpha": 1.0,
				"size": randf_range(20.0, 30.0)
			})
			
	update_ui()
	visible = true
	relic_view.queue_redraw()

func set_tool(tool_type: Tool) -> void:
	# Enforce sequential tools or let them select
	active_tool = tool_type
	Global.play_sfx.emit("tool_select")
	update_ui()

func update_ui() -> void:
	# Highlight active tool button
	btn_chisel.button_pressed = (active_tool == Tool.CHISEL)
	btn_brush.button_pressed = (active_tool == Tool.BRUSH)
	btn_spray.button_pressed = (active_tool == Tool.SPRAY)
	
	# Set helper text
	if not chisel_nodes.is_empty():
		label_instruction.text = "TAHAP 1: Gunakan Pahat untuk memecah bongkahan tanah keras!"
		btn_chisel.disabled = false
		btn_brush.disabled = true
		btn_spray.disabled = true
	elif not is_brush_complete():
		label_instruction.text = "TAHAP 2: Gunakan Kuas untuk membersihkan sisa debu tanah!"
		btn_chisel.disabled = true
		btn_brush.disabled = false
		btn_spray.disabled = true
		if active_tool == Tool.CHISEL:
			active_tool = Tool.BRUSH
	elif spray_amount < 1.0:
		label_instruction.text = "TAHAP 3: Gunakan Semprotan Air untuk mengilapkan aksara emas!"
		btn_chisel.disabled = true
		btn_brush.disabled = true
		btn_spray.disabled = false
		if active_tool != Tool.SPRAY:
			active_tool = Tool.SPRAY
	else:
		label_instruction.text = "SELESAI! Relik kuno telah bersih sempurna."
		btn_chisel.disabled = true
		btn_brush.disabled = true
		btn_spray.disabled = true
		btn_complete.visible = true
		
	# Re-evaluate highlights after automatic tool switches
	btn_chisel.button_pressed = (active_tool == Tool.CHISEL)
	btn_brush.button_pressed = (active_tool == Tool.BRUSH)
	btn_spray.button_pressed = (active_tool == Tool.SPRAY)

func is_brush_complete() -> bool:
	for node in brush_nodes:
		if node.alpha > 0.05:
			return false
	return true

func _on_complete_pressed() -> void:
	visible = false
	Global.current_state = Global.State.OVERWORLD
	if target_mound:
		target_mound.complete_cleaning()

# Input handling inside the RelicView drawing panel
func handle_view_input(local_pos: Vector2, is_drag: bool) -> void:
	if completed_steps: return
	
	match active_tool:
		Tool.CHISEL:
			if not is_drag: # Click only
				for i in range(chisel_nodes.size() - 1, -1, -1):
					if local_pos.distance_to(chisel_nodes[i]) < 24.0:
						chisel_nodes.remove_at(i)
						Global.play_sfx.emit("chisel_clink")
						Global.camera_shake.emit(2.0, 0.1)
						relic_view.queue_redraw()
						if chisel_nodes.is_empty():
							Global.play_sfx.emit("step_complete")
							set_tool(Tool.BRUSH)
						break
		Tool.BRUSH:
			if is_drag or Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
				var swiped = false
				for node in brush_nodes:
					if node.alpha > 0.0 and local_pos.distance_to(node.pos) < node.size:
						node.alpha = max(0.0, node.alpha - 0.15)
						swiped = true
				if swiped:
					if randf() < 0.15:
						Global.play_sfx.emit("brush_sweep")
					relic_view.queue_redraw()
					if is_brush_complete():
						Global.play_sfx.emit("step_complete")
						set_tool(Tool.SPRAY)
		Tool.SPRAY:
			if is_drag or Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
				# Spray inside the center zone
				if local_pos.x > 80 and local_pos.x < 240 and local_pos.y > 80 and local_pos.y < 240:
					spray_amount = min(1.0, spray_amount + 0.015)
					if randf() < 0.2:
						Global.play_sfx.emit("spray_pssh")
					relic_view.queue_redraw()
					if spray_amount >= 1.0:
						completed_steps = true
						Global.play_sfx.emit("chime_success")
						update_ui()
