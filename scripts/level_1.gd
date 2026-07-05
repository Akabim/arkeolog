extends "res://scripts/level_base.gd"

# Procedural level generation parameters
var level_width = 1280.0
var level_height = 720.0

const SHRUB_SCENE = preload("res://scenes/shrub.tscn")
const DIRT_MOUND_SCENE = preload("res://scenes/dirt_mound.tscn")
const SOCKET_SCENE = preload("res://scenes/socket.tscn")
const TORCH_SCENE = preload("res://scenes/torch.tscn")

var grass_clumps = []
var flowers = []

func _ready() -> void:
	# Enable Y-Sorting for depth layering
	y_sort_enabled = true
	
	# Define spawned elements before calling parent ready
	setup_level_boundaries()
	setup_sockets()
	setup_dirt_mounds()
	setup_torches()
	setup_shrubs()
	setup_trees()
	setup_decorative_details()
	
	# Call base class ready to calculate sockets
	super._ready()

func setup_level_boundaries() -> void:
	# Create static body for outer walls
	var borders = StaticBody2D.new()
	borders.name = "Borders"
	borders.collision_layer = 1
	borders.collision_mask = 0
	add_child(borders)
	
	var thickness = 64.0
	
	# Top Wall
	var top_col = CollisionShape2D.new()
	var top_shape = RectangleShape2D.new()
	top_shape.size = Vector2(level_width + thickness * 2, thickness)
	top_col.shape = top_shape
	top_col.position = Vector2(level_width / 2, -thickness / 2)
	borders.add_child(top_col)
	
	# Bottom Wall
	var bot_col = CollisionShape2D.new()
	var bot_shape = RectangleShape2D.new()
	bot_shape.size = Vector2(level_width + thickness * 2, thickness)
	bot_col.shape = bot_shape
	bot_col.position = Vector2(level_width / 2, level_height + thickness / 2)
	borders.add_child(bot_col)
	
	# Left Wall
	var left_col = CollisionShape2D.new()
	var left_shape = RectangleShape2D.new()
	left_shape.size = Vector2(thickness, level_height + thickness * 2)
	left_col.shape = left_shape
	left_col.position = Vector2(-thickness / 2, level_height / 2)
	borders.add_child(left_col)
	
	# Right Wall
	var right_col = CollisionShape2D.new()
	var right_shape = RectangleShape2D.new()
	right_shape.size = Vector2(thickness, level_height + thickness * 2)
	right_col.shape = right_shape
	right_col.position = Vector2(level_width + thickness / 2, level_height / 2)
	borders.add_child(right_col)

func setup_sockets() -> void:
	var sockets_node = Node2D.new()
	sockets_node.name = "Sockets"
	add_child(sockets_node)
	
	# 3 sockets corresponding to the 3 runes: HA, CA, RA
	var data = [
		{"id": "stone_1", "sym": "ha", "pos": Vector2(640, 200)},   # North: Hulu (Head/Top)
		{"id": "stone_2", "sym": "ca", "pos": Vector2(640, 360)},   # Center: Candi (Shrine/Center)
		{"id": "stone_3", "sym": "ra", "pos": Vector2(640, 520)}    # South: Ranu (Water/Bottom)
	]
	
	for s_info in data:
		var sock = SOCKET_SCENE.instantiate()
		sock.name = "Socket_" + s_info["sym"].to_upper()
		sock.relic_id = s_info["id"]
		sock.symbol_char = s_info["sym"]
		sock.position = s_info["pos"]
		sockets_node.add_child(sock)

func setup_dirt_mounds() -> void:
	var mounds_node = Node2D.new()
	mounds_node.name = "DirtMounds"
	mounds_node.y_sort_enabled = true
	add_child(mounds_node)
	
	# Place mounds scattered in different cozy areas of the map
	var data = [
		{"id": "stone_1", "sym": "ha", "name": "Pilar Kiri", "pos": Vector2(250, 200)},
		{"id": "stone_2", "sym": "ca", "name": "Prasasti Tengah", "pos": Vector2(250, 520)},
		{"id": "stone_3", "sym": "ra", "name": "Pilar Kanan", "pos": Vector2(1030, 360)}
	]
	
	for m_info in data:
		var mound = DIRT_MOUND_SCENE.instantiate()
		mound.name = "DirtMound_" + m_info["sym"].to_upper()
		mound.relic_id = m_info["id"]
		mound.symbol_char = m_info["sym"]
		mound.relic_name = m_info["name"]
		mound.position = m_info["pos"]
		mounds_node.add_child(mound)

func setup_torches() -> void:
	var torches_node = Node2D.new()
	torches_node.name = "Torches"
	torches_node.y_sort_enabled = true
	add_child(torches_node)
	
	# Torches around the ancient temple sockets in the center
	var torch_positions = [
		Vector2(560, 160), Vector2(720, 160),
		Vector2(520, 360), Vector2(760, 360),
		Vector2(560, 560), Vector2(720, 560)
	]
	
	for pos in torch_positions:
		var torch = TORCH_SCENE.instantiate()
		torch.position = pos
		torches_node.add_child(torch)

func setup_shrubs() -> void:
	var shrubs_node = Node2D.new()
	shrubs_node.name = "Shrubs"
	shrubs_node.y_sort_enabled = true
	add_child(shrubs_node)
	
	# Place shrubs to guide the player and act as cozy barricades
	# Let's place clusters of shrubs
	var spots = [
		# Center path borders
		Vector2(450, 260), Vector2(450, 300), Vector2(450, 420), Vector2(450, 460),
		Vector2(830, 260), Vector2(830, 300), Vector2(830, 420), Vector2(830, 460),
		# North obstacles
		Vector2(580, 100), Vector2(700, 100), Vector2(640, 80),
		# Scattered around mounds
		Vector2(160, 240), Vector2(320, 160), Vector2(280, 260),
		Vector2(160, 480), Vector2(320, 560), Vector2(280, 480),
		Vector2(950, 300), Vector2(1110, 420), Vector2(1000, 420)
	]
	
	# Add some randomized shrubs
	for i in range(15):
		var rand_pos = Vector2(randf_range(100, 1180), randf_range(100, 620))
		# Avoid placing too close to spawning, sockets, or mounds
		var too_close = false
		if rand_pos.distance_to(Vector2(640, 360)) < 150.0: too_close = true
		for s in spots:
			if rand_pos.distance_to(s) < 50.0: too_close = true
		if not too_close:
			spots.append(rand_pos)
			
	for pos in spots:
		var shrub = SHRUB_SCENE.instantiate()
		shrub.position = pos
		shrubs_node.add_child(shrub)

func setup_decorative_details() -> void:
	# Generate decorative grass tufts and flowers
	grass_clumps.clear()
	for i in range(80):
		grass_clumps.append({
			"pos": Vector2(randf_range(40, level_width - 40), randf_range(40, level_height - 40)),
			"size": randf_range(3, 7)
		})
		
	flowers.clear()
	for i in range(40):
		flowers.append({
			"pos": Vector2(randf_range(40, level_width - 40), randf_range(40, level_height - 40)),
			"color": Color("#FFF8E7") if randf() < 0.7 else Global.COLOR_CHEEKS
		})

func _draw() -> void:
	var grass = Global.COLOR_BG_GRASS
	var ink = Global.COLOR_INK
	var stone = Global.COLOR_STONE
	
	# 1. Fill ground background
	draw_rect(Rect2(0, 0, level_width, level_height), grass)
	
	# 2. Draw ancient ruin flagstones/temple floor in the center (shrine area)
	# Faint temple outlines
	var shrine_rect = Rect2(480, 120, 320, 480)
	draw_rect(shrine_rect, ink)
	draw_rect(Rect2(shrine_rect.position + Vector2.ONE*4, shrine_rect.size - Vector2.ONE*8), grass.darkened(0.12))
	
	# Ancient columns/pillars base elements
	var columns = [
		Vector2(500, 140), Vector2(780, 140),
		Vector2(500, 360), Vector2(780, 360),
		Vector2(500, 580), Vector2(780, 580)
	]
	for col_pos in columns:
		# Draw outline
		draw_circle(col_pos, 18.0, ink)
		draw_circle(col_pos, 15.0, stone)
		# inner detail
		draw_circle(col_pos, 9.0, stone.darkened(0.15))
		draw_circle(col_pos, 4.0, ink)
		
	# 3. Draw decorative details
	# Grass tufts
	for clump in grass_clumps:
		# Avoid drawing over the shrine floor
		if not shrine_rect.has_point(clump.pos):
			draw_circle(clump.pos, clump.size, grass.darkened(0.08))
			draw_line(clump.pos, clump.pos + Vector2(-2, -clump.size), grass.darkened(0.15), 1.5)
			draw_line(clump.pos, clump.pos + Vector2(2, -clump.size*0.8), grass.darkened(0.15), 1.5)
			
	# Flowers
	for flower in flowers:
		if not shrine_rect.has_point(flower.pos):
			# Red/yellow/white dot center with green stem
			draw_line(flower.pos, flower.pos + Vector2(0, 4), grass.darkened(0.2), 1.5)
			draw_circle(flower.pos, 2.0, flower.color)
			draw_circle(flower.pos, 0.7, ink)

func setup_trees() -> void:
	var trees_node = Node2D.new()
	trees_node.name = "Trees"
	trees_node.y_sort_enabled = true
	add_child(trees_node)
	
	var tree_scene = preload("res://scenes/tree.tscn")
	
	# Cozy layout of trees around level edges and framing the shrine
	var tree_positions = [
		Vector2(100, 100), Vector2(200, 80), Vector2(1180, 100), Vector2(1080, 80),
		Vector2(100, 620), Vector2(220, 640), Vector2(1180, 620), Vector2(1060, 640),
		Vector2(120, 360), Vector2(1160, 360),
		Vector2(380, 140), Vector2(900, 140),
		Vector2(380, 580), Vector2(900, 580)
	]
	
	for pos in tree_positions:
		var tree = tree_scene.instantiate()
		tree.position = pos
		trees_node.add_child(tree)

