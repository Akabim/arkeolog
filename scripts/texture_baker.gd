extends Node

const PLAYER_VISUAL = preload("res://scripts/player_visual.gd")
const SHRUB_VISUAL = preload("res://scripts/shrub_visual.gd")
const TREE_VISUAL = preload("res://scripts/tree_visual.gd")
const DIRT_MOUND_VISUAL = preload("res://scripts/dirt_mound_visual.gd")
const STONE_BLOCK_VISUAL = preload("res://scripts/stone_block_visual.gd")
const SOCKET_VISUAL = preload("res://scripts/socket_visual.gd")
const TORCH_VISUAL = preload("res://scripts/torch_visual.gd")

func bake_all_textures() -> void:
	print("[Texture Baker] Initiating asset texture loading system...")
	
	# Basic items
	Global.textures["player"] = await get_texture_or_bake("player", PLAYER_VISUAL, {}, Vector2(48, 48))
	Global.textures["shrub"] = await get_texture_or_bake("shrub", SHRUB_VISUAL, {}, Vector2(36, 36))
	Global.textures["tree"] = await get_texture_or_bake("tree", TREE_VISUAL, {}, Vector2(64, 96))
	Global.textures["dirt_mound"] = await get_texture_or_bake("dirt_mound", DIRT_MOUND_VISUAL, {}, Vector2(64, 48))
	
	# Torches
	Global.textures["torch_off"] = await get_texture_or_bake("torch_off", TORCH_VISUAL, {"is_lit": false}, Vector2(24, 40))
	Global.textures["torch_on1"] = await get_texture_or_bake("torch_on1", TORCH_VISUAL, {"is_lit": true}, Vector2(24, 40))
	Global.textures["torch_on2"] = await get_texture_or_bake("torch_on2", TORCH_VISUAL, {"is_lit": true}, Vector2(24, 40))
	
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

# Helper to automatically load PNG files if they exist in res://assets/sprites/, otherwise fall back to baking the procedural visuals
func get_texture_or_bake(key: String, script_type, properties: Dictionary, size: Vector2) -> Texture2D:
	var png_path = "res://assets/sprites/" + key + ".png"
	
	if ResourceLoader.exists(png_path):
		var tex = load(png_path)
		if tex:
			print("[Texture Baker] SUCCESS: Loaded sprite texture from file -> ", png_path)
			return tex
			
	# Fallback to baking
	print("[Texture Baker] PENDING: Asset file '", png_path, "' not found. Fallback to procedural baking...")
	return await bake_item(script_type, properties, size)

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
