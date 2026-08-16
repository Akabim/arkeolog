extends Node

# Game States
enum State {
	OVERWORLD,
	EXCAVATION,
	JOURNAL
}

var current_state: State = State.OVERWORLD

enum ToolType {
	NONE,
	SCYTHE,
	SHOVEL,
	PICKAXE
}

const CURSOR_HOTSPOT: Vector2 = Vector2(20.0, 22.0)

var cursor_textures: Dictionary = {}
var current_cursor_tool: ToolType = ToolType.NONE

func change_state(new_state: State) -> void:
	if current_state != new_state:
		current_state = new_state
		state_changed.emit(current_state)
		if current_state != State.OVERWORLD:
			reset_cursor()
		else:
			set_contextual_cursor(ToolType.NONE)

# Baked texture cache
var textures = {}

# Signals
signal state_changed(new_state: State)
signal excavation_started(dirt_mound)
signal excavation_completed(relic_id: String, relic_name: String, symbol_char: String, translation: String)
signal journal_toggled(is_open: bool)
signal level_restored
signal play_sfx(sfx_name: String)
signal camera_shake(intensity: float, duration: float)

func set_contextual_cursor(tool_type: ToolType) -> void:
	if current_state != State.OVERWORLD:
		return
	if current_cursor_tool == tool_type:
		return
	current_cursor_tool = tool_type
	var tex: Texture2D = cursor_textures.get(tool_type, cursor_textures.get(ToolType.NONE))
	if tex:
		Input.set_custom_mouse_cursor(tex, Input.CURSOR_ARROW, CURSOR_HOTSPOT)

func reset_cursor() -> void:
	if current_cursor_tool != ToolType.NONE:
		current_cursor_tool = ToolType.NONE
		var tex: Texture2D = cursor_textures.get(ToolType.NONE)
		if tex:
			Input.set_custom_mouse_cursor(tex, Input.CURSOR_ARROW, CURSOR_HOTSPOT)

# Color Palette Reference
const COLOR_BG_GRASS = Color("#4D7C59")
const COLOR_OBSTACLES = Color("#2F5233")
const COLOR_DIRT = Color("#6F4E37")
const COLOR_STONE = Color("#8C8D8A")
const COLOR_GOLD = Color("#D4AF37")
const COLOR_INK = Color("#111827")
const COLOR_WHITE = Color("#F3F4F6")
const COLOR_CHEEKS = Color("#FCD34D")

# Relic / Translation data
# Dictionary mapping relic_id to its name, ancient inscription text, Indonesian translation, and socket hint
# Dictionary mapping relic_id to its RelicData resource
var dictionary = {}

# Player Game Progress
var discovered_symbols = [] # Array of String (holds relic_ids: e.g. ["stone_1"])
var deciphered_symbols = {} # Dictionary of String (relic_id) -> String (translation)
var solved_sockets = {} # Dictionary mapping socket ID to stone ID
var total_sockets_in_level = 0
var completed_levels = []

func _ready() -> void:
	setup_input_map()
	load_relic_blueprints()
	preload_textures()
	init_cursors()

func init_cursors() -> void:
	cursor_textures = {
		ToolType.NONE: load("res://assets/textures/ui/cursor/cursor_normal.png"),
		ToolType.SCYTHE: load("res://assets/textures/ui/cursor/cursor_scyte.png"),
		ToolType.SHOVEL: load("res://assets/textures/ui/cursor/cursor_shovel.png"),
		ToolType.PICKAXE: load("res://assets/textures/ui/cursor/cursor_pickaxe.png")
	}
	current_cursor_tool = ToolType.NONE
	var tex: Texture2D = cursor_textures.get(ToolType.NONE)
	if tex:
		Input.set_custom_mouse_cursor(tex, Input.CURSOR_ARROW, CURSOR_HOTSPOT)

func preload_textures() -> void:
	var paths = {
		"semak_1": "res://assets/textures/environment/semak 1 new.png",
		"semak_2": "res://assets/textures/environment/semak 2 new.png",
		"pohon_1": "res://assets/textures/environment/pohon 1.png",
		"pohon_2": "res://assets/textures/environment/pohon 2.png",
		"tree": "res://assets/textures/environment/pohon 1.png",
		"gundukan_1": "res://assets/textures/environment/Gundukan Tanah 1.png",
		"gundukan_rumput": "res://assets/textures/environment/gundukan rumput.png",
		"lubang": "res://assets/textures/environment/lubang.png",
		"torch_off": "res://assets/textures/tools/kayu obor.png",
		"torch_on": "res://assets/textures/tools/obor nyala.png",
		"batu_1": "res://assets/textures/environment/batu 1.png",
		"rumput_1": "res://assets/textures/environment/rumput 1.png",
		"cursor_scythe": "res://assets/textures/ui/cursor/scythe.png",
	}
	for key in paths:
		var p = paths[key]
		if ResourceLoader.exists(p):
			textures[key] = load(p)

func load_relic_blueprints() -> void:
	dictionary.clear()
	var path = "res://resources/relics/"
	var dir = DirAccess.open(path)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if not dir.current_is_dir() and file_name.ends_with(".tres"):
				var relic_res = load(path + file_name)
				if relic_res is RelicData:
					dictionary[relic_res.relic_id] = relic_res
			file_name = dir.get_next()

func get_texture(key: String) -> Texture2D:
	if textures.has(key):
		return textures[key]
		
	# Fallback loading: allows running tested scenes directly in Editor
	var base_key = key
	if key == "player":
		base_key = "karakter"
	elif key == "scythe":
		base_key = "sabit baru"
	elif key == "shovel":
		base_key = "sekop"
	elif key == "pickaxe":
		base_key = "Pickaxe baru"

		
	# Look up textures dynamically in the structured textures folders
	var subfolders = ["characters", "environment", "tools", "relics", "ui"]
	for sub in subfolders:
		var extensions = [".png", ".jpg"]
		for ext in extensions:
			var path = "res://assets/textures/" + sub + "/" + base_key + ext
			if ResourceLoader.exists(path):
				var tex = load(path)
				if tex:
					textures[key] = tex
					return tex
			
	# If file still doesn't exist, create a tiny default fallback to avoid crashes
	var img = Image.create(16, 16, false, Image.FORMAT_RGBA8)
	img.fill(Color.MAGENTA)
	var tex = ImageTexture.create_from_image(img)
	textures[key] = tex
	return tex

func setup_input_map() -> void:
	var inputs = {
		"move_left": [KEY_A, KEY_LEFT],
		"move_right": [KEY_D, KEY_RIGHT],
		"move_up": [KEY_W, KEY_UP],
		"move_down": [KEY_S, KEY_DOWN],
		"interact": [KEY_E, KEY_SPACE],
		"journal": [KEY_J, KEY_TAB, KEY_I]
	}
	
	for action in inputs:
		if not InputMap.has_action(action):
			InputMap.add_action(action)
		
		# Add default keyboard keys
		for keycode in inputs[action]:
			var event = InputEventKey.new()
			event.physical_keycode = keycode
			# Check if event already exists to prevent duplicates
			var already_exists = false
			for existing_event in InputMap.action_get_events(action):
				if existing_event is InputEventKey and existing_event.physical_keycode == keycode:
					already_exists = true
					break
			if not already_exists:
				InputMap.action_add_event(action, event)
	
	# Zoom In / Zoom Out mouse scroll wheel actions
	var mouse_inputs = {
		"zoom_in": MOUSE_BUTTON_WHEEL_UP,
		"zoom_out": MOUSE_BUTTON_WHEEL_DOWN
	}
	for action in mouse_inputs:
		if not InputMap.has_action(action):
			InputMap.add_action(action)
		
		var button_idx: MouseButton = mouse_inputs[action]
		var already_exists: bool = false
		for existing_event in InputMap.action_get_events(action):
			if existing_event is InputEventMouseButton and existing_event.button_index == button_idx:
				already_exists = true
				break
		if not already_exists:
			var event := InputEventMouseButton.new()
			event.button_index = button_idx
			InputMap.action_add_event(action, event)
