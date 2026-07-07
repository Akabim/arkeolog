extends Node

# Game States
enum State {
	OVERWORLD,
	EXCAVATION,
	JOURNAL
}

var current_state: State = State.OVERWORLD

func change_state(new_state: State) -> void:
	if current_state != new_state:
		current_state = new_state
		state_changed.emit(current_state)

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
# In Hanacaraka, let's map some symbols to their meaning and physical socket hints
var dictionary = {
	"ha": {"translation": "Hulu", "clue": "Utara / Atas"},
	"na": {"translation": "Nusa", "clue": "Pulau / Tengah"},
	"ca": {"translation": "Candi", "clue": "Kuil / Pusat"},
	"ra": {"translation": "Ranu", "clue": "Air / Selatan"},
	"ka": {"translation": "Katon", "clue": "Timur / Kanan"}
}

# Player Game Progress
var discovered_symbols = [] # Array of String (e.g. ["ha", "ra"])
var deciphered_symbols = {} # Dictionary of String (symbol) -> String (translation)
var solved_sockets = {} # Dictionary mapping socket ID to stone ID
var total_sockets_in_level = 0
var completed_levels = []


func _ready() -> void:
	setup_input_map()

func get_texture(key: String) -> Texture2D:
	if textures.has(key):
		return textures[key]
		
	# Fallback loading: allows running tested scenes directly in Editor
	var base_key = key
	if key == "player":
		base_key = "karakter"
	elif key == "scythe":
		base_key = "scyte"
		
	var png_path = "res://assets/sprites/" + base_key + ".png"
	if ResourceLoader.exists(png_path):
		var tex = load(png_path)
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
