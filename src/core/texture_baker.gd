extends Node

const PLAYER_VISUAL = preload("res://src/entities/player/player_visual.gd")
const SHRUB_VISUAL = preload("res://src/entities/obstacles/shrub_visual.gd")
const TREE_VISUAL = preload("res://src/entities/obstacles/tree_visual.gd")
const DIRT_MOUND_VISUAL = preload("res://src/entities/dirt_mound/dirt_mound_visual.gd")
const STONE_BLOCK_VISUAL = preload("res://src/entities/stone_block/stone_block_visual.gd")
const SOCKET_VISUAL = preload("res://src/entities/socket/socket_visual.gd")
const TORCH_VISUAL = preload("res://src/entities/obstacles/torch_visual.gd")

func bake_all_textures() -> void:
	print("[Texture Baker] Initiating asset texture loading system...")
	
	# Basic items (Note: Player uses the custom named 'karakter.png')
	Global.textures["player"] = await get_texture_or_bake("karakter", PLAYER_VISUAL, {}, Vector2(80, 80))
	Global.textures["shrub"] = await get_texture_or_bake("shrub", SHRUB_VISUAL, {}, Vector2(36, 36))
	Global.textures["tree"] = await get_texture_or_bake("tree", TREE_VISUAL, {}, Vector2(64, 96))
	Global.textures["dirt_mound"] = await get_texture_or_bake("dirt_mound", DIRT_MOUND_VISUAL, {}, Vector2(64, 48))
	
	# Load hand and tools with fallbacks
	Global.textures["hand"] = load_or_create_fallback("hand", Vector2(16, 16), Color.WHITE)
	Global.textures["scythe"] = load_or_create_fallback("Tools/scythe", Vector2(32, 32), Color.DARK_GRAY)
	Global.textures["shovel"] = load_or_create_fallback("Tools/sekop", Vector2(32, 32), Color.GRAY)
	
	# Torches
	Global.textures["torch_off"] = await get_texture_or_bake("Tools/kayu obor", TORCH_VISUAL, {"is_lit": false}, Vector2(24, 40))
	Global.textures["torch_on1"] = await get_texture_or_bake("Tools/obor nyala", TORCH_VISUAL, {"is_lit": true}, Vector2(24, 40))
	Global.textures["torch_on2"] = await get_texture_or_bake("Tools/obor nyala", TORCH_VISUAL, {"is_lit": true}, Vector2(24, 40))
	
	# Stone blocks
	var symbols = ["ha", "na", "ca", "ra", "ka"]
	for sym in symbols:
		var key = "stone_" + sym
		Global.textures[key] = await get_texture_or_bake(key, STONE_BLOCK_VISUAL, {"symbol_char": sym}, Vector2(40, 40))
		
	# Sockets
	for sym in symbols:
		var off_key = "socket_" + sym + "_off"
		Global.textures[off_key] = await get_texture_or_bake(off_key, SOCKET_VISUAL, {"symbol_char": sym, "is_solved": false, "tolerance_radius": 16.0}, Vector2(48, 48))
		
		var on_key = "socket_" + sym + "_on"
		Global.textures[on_key] = await get_texture_or_bake(on_key, SOCKET_VISUAL, {"symbol_char": sym, "is_solved": true, "tolerance_radius": 16.0}, Vector2(48, 48))
		
	print("[Texture Baker] Texture loading system complete! Cache size: ", Global.textures.size())

# Helper to automatically load PNG files if they exist in assets/textures/ subfolders, otherwise fall back to baking
func get_texture_or_bake(key: String, script_type, properties: Dictionary, size: Vector2) -> Texture2D:
	var subfolders = ["player", "environment", "relics", "ui"]
	for sub in subfolders:
		var path = "res://assets/textures/" + sub + "/" + key + ".png"
		if ResourceLoader.exists(path):
			var tex = load(path)
			if tex:
				print("[Texture Baker] SUCCESS: Loaded sprite texture from file -> ", path)
				return tex
			
	# Fallback to baking
	print("[Texture Baker] PENDING: Asset file '", key, "' not found in textures subfolders. Fallback to procedural baking...")
	return await bake_item(script_type, properties, size)

func load_or_create_fallback(key: String, fallback_size: Vector2, fallback_color: Color) -> Texture2D:
	var subfolders = ["player", "environment", "relics", "ui"]
	for sub in subfolders:
		var path = "res://assets/textures/" + sub + "/" + key + ".png"
		if ResourceLoader.exists(path):
			var tex = load(path)
			if tex:
				print("[Texture Baker] SUCCESS: Loaded tool/hand texture -> ", path)
				return tex
			
	# Fallback: create a small colored square/circle
	print("[Texture Baker] WARNING: Tool/hand asset '", key, "' not found in structured folders. Creating fallback.")
	var img = Image.create(int(fallback_size.x), int(fallback_size.y), false, Image.FORMAT_RGBA8)
	img.fill(fallback_color)
	return ImageTexture.create_from_image(img)

func bake_item(script_type, properties: Dictionary, size: Vector2) -> Texture2D:
	var viewport = SubViewport.new()
	viewport.size = Vector2i(size.x, size.y)
	viewport.transparent_bg = true
	viewport.render_target_clear_mode = SubViewport.CLEAR_MODE_ALWAYS
	viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
	add_child(viewport)
	
	var node = Node2D.new()
	node.set_script(script_type)
	for prop in properties:
		node.set(prop, properties[prop])
		
	node.position = size / 2.0
	viewport.add_child(node)
	
	# Wait 2 frames for rendering pipeline compilation
	await get_tree().process_frame
	await get_tree().process_frame
	
	var img = viewport.get_texture().get_image()
	var tex = ImageTexture.create_from_image(img)
	
	# Cleanup
	viewport.queue_free()
	return tex
