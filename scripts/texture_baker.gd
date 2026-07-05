extends Node

const PLAYER_VISUAL = preload("res://scripts/player_visual.gd")
const SHRUB_VISUAL = preload("res://scripts/shrub_visual.gd")
const TREE_VISUAL = preload("res://scripts/tree_visual.gd")
const DIRT_MOUND_VISUAL = preload("res://scripts/dirt_mound_visual.gd")
const STONE_BLOCK_VISUAL = preload("res://scripts/stone_block_visual.gd")
const SOCKET_VISUAL = preload("res://scripts/socket_visual.gd")
const TORCH_VISUAL = preload("res://scripts/torch_visual.gd")

func bake_all_textures() -> void:
	print("[Texture Baker] Starting procedural texture baking...")
	
	# Basic items
	Global.textures["player"] = await bake_item(PLAYER_VISUAL, {}, Vector2(48, 48))
	Global.textures["shrub"] = await bake_item(SHRUB_VISUAL, {}, Vector2(36, 36))
	Global.textures["tree"] = await bake_item(TREE_VISUAL, {}, Vector2(64, 96))
	Global.textures["dirt_mound"] = await bake_item(DIRT_MOUND_VISUAL, {}, Vector2(64, 48))
	
	# Torches
	Global.textures["torch_off"] = await bake_item(TORCH_VISUAL, {"is_lit": false}, Vector2(24, 40))
	Global.textures["torch_on1"] = await bake_item(TORCH_VISUAL, {"is_lit": true}, Vector2(24, 40))
	Global.textures["torch_on2"] = await bake_item(TORCH_VISUAL, {"is_lit": true}, Vector2(24, 40))
	
	# Stone blocks
	var symbols = ["ha", "na", "ca", "ra", "ka"]
	for sym in symbols:
		Global.textures["stone_" + sym] = await bake_item(STONE_BLOCK_VISUAL, {"symbol_char": sym}, Vector2(40, 40))
		
	# Sockets
	for sym in symbols:
		Global.textures["socket_" + sym + "_off"] = await bake_item(SOCKET_VISUAL, {"symbol_char": sym, "is_solved": false, "tolerance_radius": 16.0}, Vector2(48, 48))
		Global.textures["socket_" + sym + "_on"] = await bake_item(SOCKET_VISUAL, {"symbol_char": sym, "is_solved": true, "tolerance_radius": 16.0}, Vector2(48, 48))
		
	print("[Texture Baker] All textures baked successfully! Cache count: ", Global.textures.size())

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
	
	# Wait 2 frames for rendering pipeline to complete compilation and rasterization
	await get_tree().process_frame
	await get_tree().process_frame
	
	var img = viewport.get_texture().get_image()
	var tex = ImageTexture.create_from_image(img)
	
	# Cleanup
	viewport.queue_free()
	return tex
