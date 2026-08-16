extends CanvasLayer

@onready var main_panel: Control = get_node_or_null("Control/DeskPanel") if has_node("Control/DeskPanel") else $Control
@onready var tool_brush: TextureButton = get_node_or_null("Control/Tools/ToolBrush") if has_node("Control/Tools/ToolBrush") else get_node_or_null("Control/DeskPanel/ToolBrush")
@onready var tool_spray: TextureButton = get_node_or_null("Control/Tools/ToolSpray") if has_node("Control/Tools/ToolSpray") else get_node_or_null("Control/DeskPanel/ToolSpray")
@onready var tool_chisel: TextureButton = get_node_or_null("Control/Tools/ToolChisel") if has_node("Control/Tools/ToolChisel") else get_node_or_null("Control/DeskPanel/ToolChisel")
@onready var btn_complete: TextureButton = get_node_or_null("Control/BtnComplete") if has_node("Control/BtnComplete") else get_node_or_null("Control/DeskPanel/BtnComplete")
@onready var label_instruction: Label = get_node_or_null("Control/DeskPanel/NotePanel/InstructionLabel")
@onready var cloth_panel: Control = get_node_or_null("Control/ClothPanel") if has_node("Control/ClothPanel") else get_node_or_null("Control/DeskPanel/ClothPanel")
@onready var relic_view: Control = get_node_or_null("Control/ClothPanel/RelicView") if has_node("Control/ClothPanel/RelicView") else get_node_or_null("Control/DeskPanel/ClothPanel/RelicView")
@onready var chisel_particles: CPUParticles2D = get_node_or_null("Control/ClothPanel/ChiselParticles") if has_node("Control/ClothPanel/ChiselParticles") else (get_node_or_null("Control/ClothPanel/RelicView/ChiselParticles") if has_node("Control/ClothPanel/RelicView/ChiselParticles") else get_node_or_null("Control/DeskPanel/ClothPanel/RelicView/ChiselParticles"))
@onready var brush_particles: CPUParticles2D = get_node_or_null("Control/ClothPanel/BrushParticles") if has_node("Control/ClothPanel/BrushParticles") else (get_node_or_null("Control/ClothPanel/RelicView/BrushParticles") if has_node("Control/ClothPanel/RelicView/BrushParticles") else get_node_or_null("Control/DeskPanel/ClothPanel/RelicView/BrushParticles"))
@onready var spray_particles: CPUParticles2D = get_node_or_null("Control/ClothPanel/SprayParticles") if has_node("Control/ClothPanel/SprayParticles") else (get_node_or_null("Control/ClothPanel/RelicView/SprayParticles") if has_node("Control/ClothPanel/RelicView/SprayParticles") else get_node_or_null("Control/DeskPanel/ClothPanel/RelicView/SprayParticles"))
@onready var sparkle_particles: CPUParticles2D = get_node_or_null("Control/ClothPanel/SparkleParticles") if has_node("Control/ClothPanel/SparkleParticles") else (get_node_or_null("Control/ClothPanel/RelicView/SparkleParticles") if has_node("Control/ClothPanel/RelicView/SparkleParticles") else get_node_or_null("Control/DeskPanel/ClothPanel/RelicView/SparkleParticles"))

# Aliases for internal backwards compatibility
@onready var btn_chisel: TextureButton = tool_chisel
@onready var btn_brush: TextureButton = tool_brush
@onready var btn_spray: TextureButton = tool_spray

# Game State
enum Tool { CHISEL, BRUSH, SPRAY }
var active_tool: Tool = Tool.CHISEL

var target_mound = null
var relic_id: String = ""
var symbol_char: String = "ha"
var relic_name: String = ""

# Preloaded assets fallback
var fallback_prasasti: Texture2D = preload("res://assets/textures/relics/Prasasti.png")
var fallback_tulisan: Texture2D = preload("res://assets/textures/relics/Tulisan.png")
var fallback_tanah: Texture2D = preload("res://assets/textures/relics/Tanah.png")
var fallback_batu1: Texture2D = preload("res://assets/textures/relics/Batu 1.png")
var fallback_batu2: Texture2D = preload("res://assets/textures/relics/Batu 2.png")
var fallback_batu3: Texture2D = preload("res://assets/textures/relics/Batu 3.png")

# Outline Shader Resource
var outline_shader: Shader = preload("res://src/ui/excavation/tool_outline.gdshader")

# Active textures for the current relic
var tex_prasasti: Texture2D
var tex_tulisan: Texture2D
var tex_tanah: Texture2D

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

# Diegetic tool interaction state
var _tool_base_y: Dictionary = {}
var _tool_tweens: Dictionary = {}
var _bounce_tweens: Dictionary = {}
var _ui_shake_tween: Tween = null
var _cloth_panel_base_pos: Vector2 = Vector2.ZERO

# Rock configurations
class Rock:
	var texture: Texture2D
	var _image: Image = null
	var center: Vector2
	var clicks_left: int
	var max_clicks: int
	var full_canvas: bool
	var destroyed: bool = false
	
	func _init(tex: Texture2D, pos: Vector2, clicks: int, is_full: bool = true) -> void:
		texture = tex
		center = pos
		clicks_left = clicks
		max_clicks = clicks
		full_canvas = is_full

	func get_image() -> Image:
		if _image == null and texture != null:
			var raw_img: Image = texture.get_image()
			if raw_img:
				_image = raw_img.duplicate()
				if _image.is_compressed():
					_image.decompress()
		return _image


var rocks: Array = []
var spray_amount: float = 0.0
var completed_steps: bool = false

func _ready() -> void:
	visible = false
	
	var tools_container: Control = get_node_or_null("Control/Tools") as Control
	if tools_container:
		tools_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
		
	if cloth_panel:
		cloth_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE

	if btn_complete:
		btn_complete.visible = false
		btn_complete.pressed.connect(_on_complete_pressed)
		_setup_tool_shader(btn_complete)
		_setup_click_mask(btn_complete)
		_tool_base_y[btn_complete] = btn_complete.position.y
		btn_complete.mouse_entered.connect(func() -> void:
			Global.play_sfx.emit("hover")
			_animate_tool(btn_complete, true, true)
		)
		btn_complete.mouse_exited.connect(func() -> void:
			_animate_tool(btn_complete, false, false)
		)
	
	# Save base Y positions, shader, and click mask for diegetic tools
	var tools: Array[TextureButton] = [tool_brush, tool_spray, tool_chisel]
	for t in tools:
		if t:
			t.pivot_offset = t.size / 2.0
			_tool_base_y[t] = t.position.y
			_setup_tool_shader(t)
			_setup_click_mask(t)
	
	# Connect diegetic hover & click events
	if tool_chisel: _setup_tool_events(tool_chisel, Tool.CHISEL)
	if tool_brush: _setup_tool_events(tool_brush, Tool.BRUSH)
	if tool_spray: _setup_tool_events(tool_spray, Tool.SPRAY)
	
	# Generate smooth anti-aliased round white circle texture for particles
	var circle_img: Image = Image.create(32, 32, false, Image.FORMAT_RGBA8)
	var center: Vector2 = Vector2(16.0, 16.0)
	for x in range(32):
		for y in range(32):
			var dist: float = Vector2(float(x) + 0.5, float(y) + 0.5).distance_to(center)
			if dist <= 16.0:
				var alpha: float = clampf(1.0 - (dist - 15.0), 0.0, 1.0)
				circle_img.set_pixel(x, y, Color(1.0, 1.0, 1.0, alpha))
			else:
				circle_img.set_pixel(x, y, Color(0.0, 0.0, 0.0, 0.0))
	var circle_tex: ImageTexture = ImageTexture.create_from_image(circle_img)
	
	if chisel_particles:
		chisel_particles.texture = circle_tex
	if brush_particles:
		brush_particles.texture = circle_tex
		brush_particles.amount = 28
		brush_particles.lifetime = 0.65
		brush_particles.scale_amount_min = 0.4
		brush_particles.scale_amount_max = 1.0
		brush_particles.initial_velocity_min = 70.0
		brush_particles.initial_velocity_max = 150.0
		brush_particles.explosiveness = 0.85
		brush_particles.spread = 180.0
	if spray_particles:
		spray_particles.texture = circle_tex
	if sparkle_particles:
		sparkle_particles.texture = circle_tex
	
	Global.excavation_started.connect(start_game)
	
	# Standalone F6 test support
	if target_mound == null:
		if get_tree().current_scene == self or (get_tree().current_scene and get_tree().current_scene.scene_file_path.contains("excavation_overlay")):
			start_game(null)

func shake_ui(intensity: float, duration: float) -> void:
	if not cloth_panel:
		return
		
	if _ui_shake_tween and _ui_shake_tween.is_running():
		_ui_shake_tween.kill()
		cloth_panel.position = _cloth_panel_base_pos
	else:
		_cloth_panel_base_pos = cloth_panel.position
		
	_ui_shake_tween = create_tween()
	var steps: int = int(max(3, duration / 0.03))
	var step_duration: float = duration / float(steps)
	
	for i in range(steps):
		var current_intensity: float = intensity * (1.0 - float(i) / float(steps))
		var offset: Vector2 = Vector2(
			randf_range(-current_intensity, current_intensity),
			randf_range(-current_intensity, current_intensity)
		)
		_ui_shake_tween.tween_property(cloth_panel, "position", _cloth_panel_base_pos + offset, step_duration)
		
	_ui_shake_tween.tween_property(cloth_panel, "position", _cloth_panel_base_pos, step_duration)

func _setup_click_mask(button: TextureButton) -> void:
	if not button or not button.texture_normal:
		return
	var raw_img: Image = button.texture_normal.get_image()
	if raw_img:
		var img: Image = raw_img.duplicate()
		if img.is_compressed():
			img.decompress()
		var bitmap: BitMap = BitMap.new()
		bitmap.create_from_image_alpha(img, 0.1)
		button.texture_click_mask = bitmap

func _setup_tool_shader(button: TextureButton) -> void:
	if not button:
		return
	var mat: ShaderMaterial = ShaderMaterial.new()
	mat.shader = outline_shader
	mat.set_shader_parameter("enabled", false)
	mat.set_shader_parameter("outline_color", Color(1.0, 1.0, 1.0, 1.0))
	mat.set_shader_parameter("width", 3.0)
	button.material = mat

func _set_tool_outline(button: TextureButton, enabled: bool) -> void:
	if button and button.material is ShaderMaterial:
		(button.material as ShaderMaterial).set_shader_parameter("enabled", enabled)

func _unhandled_input(event: InputEvent) -> void:
	if not visible or completed_steps: return
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_1: set_tool(Tool.CHISEL)
			KEY_2: set_tool(Tool.BRUSH)
			KEY_3: set_tool(Tool.SPRAY)

func _setup_tool_events(tool_node: TextureButton, tool_enum: Tool) -> void:
	tool_node.mouse_filter = Control.MOUSE_FILTER_STOP
	tool_node.mouse_entered.connect(func() -> void: _on_tool_mouse_entered(tool_node))
	tool_node.mouse_exited.connect(func() -> void: _on_tool_mouse_exited(tool_node, tool_enum))
	tool_node.pressed.connect(func() -> void: set_tool(tool_enum))

func _on_tool_mouse_entered(tool_node: TextureButton) -> void:
	Global.play_sfx.emit("hover")
	_animate_tool(tool_node, true, true)

func _on_tool_mouse_exited(tool_node: TextureButton, tool_enum: Tool) -> void:
	if active_tool == tool_enum:
		_animate_tool(tool_node, true, true)
	else:
		_animate_tool(tool_node, false, false)

func set_tool(tool_type: Tool) -> void:
	active_tool = tool_type
	Global.play_sfx.emit("tool_select")
	
	var target_node: TextureButton = null
	match tool_type:
		Tool.CHISEL: target_node = tool_chisel
		Tool.BRUSH: target_node = tool_brush
		Tool.SPRAY: target_node = tool_spray
		
	if target_node:
		_bounce_tool(target_node)
		
	_update_tool_visual_states()
	update_ui()

func _bounce_tool(node: TextureButton) -> void:
	if not node: return
	node.pivot_offset = node.size / 2.0
	if _bounce_tweens.has(node) and _bounce_tweens[node] is Tween and _bounce_tweens[node].is_running():
		_bounce_tweens[node].kill()
	var tween: Tween = create_tween()
	tween.tween_property(node, "scale", Vector2(1.1, 1.1), 0.08).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	tween.tween_property(node, "scale", Vector2.ONE, 0.08).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_QUAD)
	_bounce_tweens[node] = tween

func _update_tool_visual_states() -> void:
	var tools_map: Dictionary = {
		Tool.BRUSH: tool_brush,
		Tool.SPRAY: tool_spray,
		Tool.CHISEL: tool_chisel
	}
	for t_enum in tools_map:
		var node: TextureButton = tools_map[t_enum]
		if not node: continue
		var is_active: bool = (active_tool == t_enum)
		var local_m: Vector2 = node.get_local_mouse_position()
		var is_hovered: bool = Rect2(Vector2.ZERO, node.size).has_point(local_m)
		if is_active or is_hovered:
			_animate_tool(node, true, true)
		else:
			_animate_tool(node, false, false)

func _animate_tool(node: TextureButton, lifted: bool, highlighted: bool) -> void:
	if not node: return
	var base_y: float = _tool_base_y.get(node, node.position.y)
	var target_y: float = base_y - 12.0 if lifted else base_y
	
	_set_tool_outline(node, highlighted)
	
	if _tool_tweens.has(node) and _tool_tweens[node] is Tween and _tool_tweens[node].is_running():
		_tool_tweens[node].kill()
		
	var tween: Tween = create_tween()
	tween.tween_property(node, "position:y", target_y, 0.18).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	_tool_tweens[node] = tween

func start_game(mound) -> void:
	target_mound = mound
	if mound:
		relic_id = mound.relic_id
		symbol_char = mound.symbol_char
		relic_name = mound.relic_name
	else:
		relic_id = ""
		symbol_char = "ha"
		relic_name = ""
	
	# Get RelicData Resource from global dictionary
	var relic_data: RelicData = Global.dictionary.get(relic_id)
	
	# Reset states
	active_tool = Tool.CHISEL
	completed_steps = false
	spray_amount = 0.0
	if btn_complete: btn_complete.visible = false
	
	# Override active textures from Resource, or use preloaded fallbacks
	if relic_data:
		tex_prasasti = relic_data.base_texture if relic_data.base_texture else fallback_prasasti
		tex_tulisan = relic_data.writing_texture if relic_data.writing_texture else fallback_tulisan
		tex_tanah = relic_data.dirt_texture if relic_data.dirt_texture else fallback_tanah
	else:
		tex_prasasti = fallback_prasasti
		tex_tulisan = fallback_tulisan
		tex_tanah = fallback_tanah
	
	# Initialize Rocks from Resource, or use defaults
	rocks.clear()
	if relic_data and not relic_data.rocks.is_empty():
		for r_data in relic_data.rocks:
			if r_data and r_data.texture:
				rocks.append(Rock.new(r_data.texture, r_data.custom_position, r_data.max_clicks, r_data.full_canvas))
	else:
		rocks = [
			Rock.new(fallback_batu1, Vector2(90, 130), 3, true),
			Rock.new(fallback_batu2, Vector2(230, 90), 3, true),
			Rock.new(fallback_batu3, Vector2(190, 190), 3, true)
		]
	
	# Initialize Brush Layer (Soil)
	var base_tanah: Image = tex_tanah.get_image()
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
	
	# Turn off sparkles initially
	if sparkle_particles:
		sparkle_particles.emitting = false
		
	# Smooth fade-in and bounce-scale transition
	if main_panel:
		main_panel.modulate.a = 0.0
		main_panel.scale = Vector2(0.92, 0.92)
		main_panel.pivot_offset = Vector2(960, 540) # Center of 1920x1080 screen
		
	visible = true
	if relic_view: relic_view.queue_redraw()
	
	if main_panel:
		var tween: Tween = create_tween().set_parallel(true)
		tween.tween_property(main_panel, "modulate:a", 1.0, 0.45).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
		tween.tween_property(main_panel, "scale", Vector2.ONE, 0.45).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	
	_update_tool_visual_states()
	update_ui()

func update_ui() -> void:
	if tool_chisel: tool_chisel.disabled = completed_steps
	if tool_brush: tool_brush.disabled = completed_steps
	if tool_spray: tool_spray.disabled = completed_steps
	
	# Set helper text based on puzzle progress
	var chisel_done: bool = is_chisel_complete()
	var brush_done: bool = is_brush_complete()
	
	if label_instruction:
		if not chisel_done:
			label_instruction.text = "Gunakan Pahat untuk memecah bongkahan batu besar (klik 3x langsung pada batu)!"
		elif not brush_done:
			label_instruction.text = "Gunakan Kuas untuk membersihkan sisa tanah cokelat hingga bersih!"
		elif not completed_steps:
			label_instruction.text = "Gunakan Semprotan Air untuk mengilapkan aksara emas!"
		else:
			label_instruction.text = "SELESAI! Relik kuno telah bersih sempurna."
	
	if completed_steps:
		if tool_chisel: tool_chisel.disabled = true
		if tool_brush: tool_brush.disabled = true
		if tool_spray: tool_spray.disabled = true
		if btn_complete: btn_complete.visible = true

func is_chisel_complete() -> bool:
	for r in rocks:
		if not r.destroyed:
			return false
	return true

func is_brush_complete() -> bool:
	var ratio: float = float(erased_dirt_pixels) / float(total_dirt_pixels)
	return ratio >= 0.96 # Requires 96% completeness for high-res clean-up

func _on_complete_pressed() -> void:
	InventoryManager.add_fragment(symbol_char)
	var ctrl: Control = get_node_or_null("Control")
	if ctrl:
		var tween: Tween = create_tween()
		tween.tween_property(ctrl, "modulate:a", 0.0, 0.35).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)
		tween.tween_callback(func() -> void:
			visible = false
			ctrl.modulate.a = 1.0
			Global.change_state(Global.State.OVERWORLD)
			if target_mound:
				target_mound.complete_cleaning()
		)
	else:
		visible = false
		Global.change_state(Global.State.OVERWORLD)
		if target_mound:
			target_mound.complete_cleaning()

func get_rock_at_pos(local_pos: Vector2) -> Rock:
	var view_size: Vector2 = relic_view.size if (relic_view and relic_view.size != Vector2.ZERO) else Vector2(640, 560)
	for r in rocks:
		var rock_item: Rock = r as Rock
		if rock_item and not rock_item.destroyed:
			var r_w: int = rock_item.texture.get_width()
			var r_h: int = rock_item.texture.get_height()
			var r_scale: Vector2 = Vector2(float(r_w) / view_size.x, float(r_h) / view_size.y)
			
			if rock_item.full_canvas:
				var rx: int = int(local_pos.x * r_scale.x)
				var ry: int = int(local_pos.y * r_scale.y)
				if rx >= 0 and rx < r_w and ry >= 0 and ry < r_h:
					var img: Image = rock_item.get_image()
					if img and img.get_pixel(rx, ry).a > 0.1:
						return rock_item
			else:
				var half_size: Vector2 = Vector2(r_w, r_h) / (2.0 * r_scale)
				var center_in_view: Vector2 = Vector2(rock_item.center.x * (view_size.x / 320.0), rock_item.center.y * (view_size.y / 280.0))
				var rect: Rect2 = Rect2(center_in_view - half_size, half_size * 2.0)
				if rect.has_point(local_pos):
					var rx: int = int((local_pos.x - rect.position.x) * r_scale.x)
					var ry: int = int((local_pos.y - rect.position.y) * r_scale.y)
					if rx >= 0 and rx < r_w and ry >= 0 and ry < r_h:
						var img: Image = rock_item.get_image()
						if img and img.get_pixel(rx, ry).a > 0.1:
							return rock_item
	return null


func handle_view_input(local_pos: Vector2, is_drag: bool) -> void:
	if completed_steps: return
	
	var tex_w: int = brush_image.get_width()
	var tex_h: int = brush_image.get_height()
	var view_size: Vector2 = relic_view.size if (relic_view and relic_view.size != Vector2.ZERO) else Vector2(640, 560)
	var map_scale: Vector2 = Vector2(float(tex_w) / view_size.x, float(tex_h) / view_size.y)
	var mapped_pos: Vector2 = Vector2(local_pos.x * map_scale.x, local_pos.y * map_scale.y)
	
	match active_tool:
		Tool.CHISEL:
			if not is_drag: # Click only
				var hit_rock: Rock = get_rock_at_pos(local_pos)
				if hit_rock:
					hit_rock.clicks_left -= 1
					
					var particle_pos: Vector2 = (relic_view.position + local_pos) if relic_view else local_pos
					
					# Emitting chisel rock shards
					if chisel_particles:
						chisel_particles.position = particle_pos
						chisel_particles.restart()
						
					shake_ui(4.0, 0.12)
					Global.camera_shake.emit(3.0, 0.1)
					Global.play_sfx.emit("chisel_clink")
					
					if hit_rock.clicks_left <= 0:
						hit_rock.destroyed = true
						# Emitting extra chisel debris shards
						if chisel_particles:
							chisel_particles.position = particle_pos
							chisel_particles.restart()
						shake_ui(10.0, 0.25)
						Global.camera_shake.emit(6.0, 0.2)
						Global.play_sfx.emit("step_complete")
						
					if relic_view: relic_view.queue_redraw()
					update_ui()
					
		Tool.BRUSH:
			if is_drag or Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
				var changed: bool = erase_brush_circle(mapped_pos, 25.0 * map_scale.x)
				if changed:
					if brush_particles and randf() < 0.25:
						brush_particles.position = (relic_view.position + local_pos) if relic_view else local_pos
						brush_particles.restart()
					if randf() < 0.08:
						Global.play_sfx.emit("brush_sweep")
					if relic_view: relic_view.queue_redraw()
					update_ui()
						
		Tool.SPRAY:
			if is_drag or Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
				var changed: bool = reveal_spray_circle(mapped_pos, 20.0 * map_scale.x)
				if changed:
					if spray_particles:
						spray_particles.position = (relic_view.position + local_pos) if relic_view else local_pos
						spray_particles.restart()
					if randf() < 0.12:
						Global.play_sfx.emit("spray_pssh")
					if relic_view: relic_view.queue_redraw()
					
					var ratio: float = float(revealed_gold_pixels) / float(total_gold_pixels)
					spray_amount = ratio
					if ratio >= 0.96:
						completed_steps = true
						Global.play_sfx.emit("chime_success")
						if sparkle_particles:
							if relic_view:
								sparkle_particles.position = relic_view.position + relic_view.size / 2.0
							sparkle_particles.emitting = true
					update_ui()

func erase_brush_circle(pos: Vector2, radius: float) -> bool:
	if not brush_image: return false
	
	var start_x: int = max(0, int(pos.x - radius))
	var end_x: int = min(brush_image.get_width(), int(pos.x + radius))
	var start_y: int = max(0, int(pos.y - radius))
	var end_y: int = min(brush_image.get_height(), int(pos.y + radius))
	
	var changed: bool = false
	var inner_radius: float = radius * 0.5
	var outer_diff: float = radius - inner_radius
	
	for x in range(start_x, end_x):
		for y in range(start_y, end_y):
			var dx: float = x - pos.x
			var dy: float = y - pos.y
			var dist: float = sqrt(dx*dx + dy*dy)
			if dist <= radius:
				var col: Color = brush_image.get_pixel(x, y)
				if col.a > 0.01:
					var target_alpha: float = 0.0
					if dist > inner_radius:
						var factor: float = (dist - inner_radius) / outer_diff
						target_alpha = col.a * factor
						
					if col.a > target_alpha:
						brush_image.set_pixel(x, y, Color(col.r, col.g, col.b, target_alpha))
						if col.a > 0.05 and target_alpha <= 0.05:
							erased_dirt_pixels += 1
						changed = true
					
	if changed:
		brush_texture.update(brush_image)
	return changed

func reveal_spray_circle(pos: Vector2, radius: float) -> bool:
	if not spray_image or not tulisan_image: return false
	
	var start_x: int = max(0, int(pos.x - radius))
	var end_x: int = min(spray_image.get_width(), int(pos.x + radius))
	var start_y: int = max(0, int(pos.y - radius))
	var end_y: int = min(spray_image.get_height(), int(pos.y + radius))
	
	var changed: bool = false
	var inner_radius: float = radius * 0.5
	var outer_diff: float = radius - inner_radius
	
	for x in range(start_x, end_x):
		for y in range(start_y, end_y):
			var dx: float = x - pos.x
			var dy: float = y - pos.y
			var dist: float = sqrt(dx*dx + dy*dy)
			if dist <= radius:
				var gold_col: Color = tulisan_image.get_pixel(x, y)
				if gold_col.a > 0.01:
					var target_alpha: float = gold_col.a
					if dist > inner_radius:
						var factor: float = 1.0 - (dist - inner_radius) / outer_diff
						target_alpha = gold_col.a * factor
						
					var current_col: Color = spray_image.get_pixel(x, y)
					if current_col.a < target_alpha:
						spray_image.set_pixel(x, y, Color(gold_col.r, gold_col.g, gold_col.b, target_alpha))
						if current_col.a <= 0.05 and target_alpha > 0.05:
							revealed_gold_pixels += 1
						changed = true
						
	if changed:
		spray_texture.update(spray_image)
	return changed
