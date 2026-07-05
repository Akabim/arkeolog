extends RigidBody2D

@export var relic_id: String = "stone_1"
@export var symbol_char: String = "ha"
@export var relic_name: String = "Relic"

@onready var visual: Node2D = $Visual

func _ready() -> void:
	# Set up physical parameters for satisfying pushing feel
	gravity_scale = 0.0
	lock_rotation = true
	linear_damp = 12.0
	angular_damp = 12.0
	
	# Notify visual to update its redraw when symbol changes
	if visual and visual.has_method("update_symbol"):
		visual.update_symbol(symbol_char)

func _physics_process(_delta: float) -> void:
	# Trigger slight dust particle or sounds if moving fast enough
	if linear_velocity.length() > 20.0:
		if Engine.get_physics_frames() % 25 == 0:
			# Play subtle scraping sound
			Global.play_sfx.emit("stone_scrape")
