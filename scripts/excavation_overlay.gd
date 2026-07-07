extends CanvasLayer

@onready var label_instruction: Label = $Control/InstructionLabel
@onready var btn_chisel = $Control/Tools/BtnChisel
@onready var btn_brush = $Control/Tools/BtnBrush
@onready var btn_spray = $Control/Tools/BtnSpray
@onready var btn_complete = $Control/BtnComplete
@onready var relic_view = $Control/RelicView
@onready var chisel_particles = $Control/RelicView/ChiselParticles
@onready var brush_particles = $Control/RelicView/BrushParticles

# Game State
enum Tool { CHISEL, BRUSH, SPRAY }
var active_tool: Tool = Tool.CHISEL

var target_mound = null
var relic_id: String = ""
var symbol_char: String = "ha"
var relic_name: String = ""

# Preloaded assets
var tex_prasasti = preload("res://assets/tes/Prasasti.png")
var tex_tulisan = preload("res://assets/tes/Tulisan.png")
var tex_tanah = preload("res://assets/tes/Tanah.png")
var tex_batu1 = preload("res://assets/tes/Batu 1.png")
var tex_batu2 = preload("res://assets/tes/Batu 2.png")
var tex_batu3 = preload("res://assets/tes/Batu 3.png")

# Dynamic Image Data
var brush_image: Image
var brush_texture: ImageTexture
var total_dirt_pixels: int = 0
var erased_dirt_pixels: int = 0

var spray_image: Image
var spray_texture: ImageTexture
var tulisan_image: Image
var total_gold_pixels: int = 0
var revealed_gold_pixels: int = 0

# Rock configurations
class Rock:
	var texture: Texture2D
	var center: Vector2
	var clicks_left: int
	var max_clicks: int
	var destroyed: bool = false
	
	func _init(tex: Texture2D, pos: Vector2, clicks: int) -> void:
		texture = tex
		center = pos
		clicks_left = clicks
		max_clicks = clicks

var rocks = []
var spray_amount: float = 0.0
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
	
	# Initialize Rocks (3 clicks to break each, positioned dynamically)
	rocks.clear()
	rocks = [
		Rock.new(tex_batu1, Vector2(90, 130), 3),
		Rock.new(tex_batu2, Vector2(230, 90), 3),
		Rock.new(tex_batu3, Vector2(190, 190), 3)
	]
	
	# Initialize Brush Layer (Soil)
	var base_tanah = tex_tanah.get_image()
	brush_image = base_tanah.duplicate()
	brush_texture = ImageTexture.create_from_image(brush_image)
	
	# Count total opaque pixels in Tanah
	total_dirt_pixels = 0
	erased_dirt_pixels = 0
	for x in range(brush_image.get_width()):
		for y in range(brush_image.get_height()):
			if brush_image.get_pixel(x, y).a > 0.05:
				total_dirt_pixels += 1
				
	# Initialize Spray Layer (Golden inscription)
	tulisan_image = tex_tulisan.get_image()
	spray_image = Image.create(tulisan_image.get_width(), tulisan_image.get_height(), false, Image.FORMAT_RGBA8)
	spray_texture = ImageTexture.create_from_image(spray_image)
	
	# Count total gold pixels to reveal
	total_gold_pixels = 0
	revealed_gold_pixels = 0
	for x in range(tulisan_image.get_width()):
		for y in range(tulisan_image.get_height()):
			if tulisan_image.get_pixel(x, y).a > 0.05:
				total_gold_pixels += 1
				
	# Ensure safe division
	if total_dirt_pixels == 0: total_dirt_pixels = 1
	if total_gold_pixels == 0: total_gold_pixels = 1
	
	update_ui()
	visible = true
	relic_view.queue_redraw()

func set_tool(tool_type: Tool) -> void:
	active_tool = tool_type
	Global.play_sfx.emit("tool_select")
	update_ui()

func update_ui() -> void:
	btn_chisel.button_pressed = (active_tool == Tool.CHISEL)
	btn_brush.button_pressed = (active_tool == Tool.BRUSH)
	btn_spray.button_pressed = (active_tool == Tool.SPRAY)
	
	# All buttons are always enabled for sandbox freedom!
	btn_chisel.disabled = completed_steps
	btn_brush.disabled = completed_steps
	btn_spray.disabled = completed_steps
	
	# Set helper text based on puzzle progress
	var chisel_done = is_chisel_complete()
	var brush_done = is_brush_complete()
	
	if not chisel_done:
		label_instruction.text = "Gunakan Pahat untuk memecah bongkahan batu besar (klik 3x langsung pada batu)!"
	elif not brush_done:
		label_instruction.text = "Gunakan Kuas untuk membersihkan sisa tanah cokelat hingga bersih!"
	elif not completed_steps:
		label_instruction.text = "Gunakan Semprotan Air untuk mengilapkan aksara emas!"
	else:
		label_instruction.text = "SELESAI! Relik kuno telah bersih sempurna."
		btn_chisel.disabled = true
		btn_brush.disabled = true
		btn_spray.disabled = true
		btn_complete.visible = true

func is_chisel_complete() -> bool:
	for r in rocks:
		if not r.destroyed:
			return false
	return true

func is_brush_complete() -> bool:
	var ratio = float(erased_dirt_pixels) / float(total_dirt_pixels)
	return ratio >= 0.96 # Requires 96% completeness for high-res clean-up

func _on_complete_pressed() -> void:
	visible = false
	Global.change_state(Global.State.OVERWORLD)
	if target_mound:
		target_mound.complete_cleaning()

func handle_view_input(local_pos: Vector2, is_drag: bool) -> void:
	if completed_steps: return
	
	var tex_w = brush_image.get_width()
	var tex_h = brush_image.get_height()
	var map_scale = Vector2(float(tex_w)/320.0, float(tex_h)/280.0)
	var mapped_pos = Vector2(local_pos.x * map_scale.x, local_pos.y * map_scale.y)
	
	match active_tool:
		Tool.CHISEL:
			if not is_drag: # Click only
				# Pixel-perfect hit check on transparent rock layers
				var hit_rock = null
				for r in rocks:
					if not r.destroyed:
						var r_w = r.texture.get_width()
						var r_h = r.texture.get_height()
						var r_scale = Vector2(float(r_w)/320.0, float(r_h)/280.0)
						var rx = int(local_pos.x * r_scale.x)
						var ry = int(local_pos.y * r_scale.y)
						
						if rx >= 0 and rx < r_w and ry >= 0 and ry < r_h:
							var img = r.texture.get_image()
							if img.get_pixel(rx, ry).a > 0.1:
								hit_rock = r
								break
								
				if hit_rock:
					hit_rock.clicks_left -= 1
					
					# Emitting chisel rock shards
					if chisel_particles:
						chisel_particles.position = local_pos
						chisel_particles.restart()
						
					Global.camera_shake.emit(3.0, 0.1)
					Global.play_sfx.emit("chisel_clink")
					
					if hit_rock.clicks_left <= 0:
						hit_rock.destroyed = true
						# Emitting extra chisel debris shards
						if chisel_particles:
							chisel_particles.amount = 24
							chisel_particles.restart()
							chisel_particles.amount = 12 # reset back
						Global.camera_shake.emit(6.0, 0.2)
						Global.play_sfx.emit("step_complete")
						
					relic_view.queue_redraw()
					update_ui()
					
		Tool.BRUSH:
			if is_drag or Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
				var changed = erase_brush_circle(mapped_pos, 25.0 * map_scale.x)
				if changed:
					if brush_particles and randf() < 0.25:
						brush_particles.position = local_pos
						brush_particles.restart()
					if randf() < 0.08:
						Global.play_sfx.emit("brush_sweep")
					relic_view.queue_redraw()
					update_ui()
						
		Tool.SPRAY:
			if is_drag or Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
				var changed = reveal_spray_circle(mapped_pos, 20.0 * map_scale.x)
				if changed:
					if randf() < 0.12:
						Global.play_sfx.emit("spray_pssh")
					relic_view.queue_redraw()
					
					var ratio = float(revealed_gold_pixels) / float(total_gold_pixels)
					spray_amount = ratio
					if ratio >= 0.96:
						completed_steps = true
						Global.play_sfx.emit("chime_success")
					update_ui()

func erase_brush_circle(pos: Vector2, radius: float) -> bool:
	if not brush_image: return false
	
	var start_x = max(0, int(pos.x - radius))
	var end_x = min(brush_image.get_width(), int(pos.x + radius))
	var start_y = max(0, int(pos.y - radius))
	var end_y = min(brush_image.get_height(), int(pos.y + radius))
	
	var r_sq = radius * radius
	var changed = false
	
	for x in range(start_x, end_x):
		for y in range(start_y, end_y):
			var dx = x - pos.x
			var dy = y - pos.y
			if dx*dx + dy*dy <= r_sq:
				var col = brush_image.get_pixel(x, y)
				if col.a > 0.05:
					brush_image.set_pixel(x, y, Color(0, 0, 0, 0))
					erased_dirt_pixels += 1
					changed = true
					
	if changed:
		brush_texture.update(brush_image)
	return changed

func reveal_spray_circle(pos: Vector2, radius: float) -> bool:
	if not spray_image or not tulisan_image: return false
	
	var start_x = max(0, int(pos.x - radius))
	var end_x = min(spray_image.get_width(), int(pos.x + radius))
	var start_y = max(0, int(pos.y - radius))
	var end_y = min(spray_image.get_height(), int(pos.y + radius))
	
	var r_sq = radius * radius
	var changed = false
	
	for x in range(start_x, end_x):
		for y in range(start_y, end_y):
			var dx = x - pos.x
			var dy = y - pos.y
			if dx*dx + dy*dy <= r_sq:
				var target_col = spray_image.get_pixel(x, y)
				if target_col.a == 0.0:
					var gold_col = tulisan_image.get_pixel(x, y)
					if gold_col.a > 0.05:
						spray_image.set_pixel(x, y, gold_col)
						revealed_gold_pixels += 1
						changed = true
						
	if changed:
		spray_texture.update(spray_image)
	return changed
