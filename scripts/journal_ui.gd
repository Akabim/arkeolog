extends CanvasLayer

@onready var container: Control = $Control
@onready var list_discovered: ItemList = $Control/Book/LeftPage/ListDiscovered
@onready var label_no_relics: Label = $Control/Book/LeftPage/LabelNoRelics

@onready var detail_panel: Control = $Control/Book/RightPage/DetailPanel
@onready var detail_prompt: Label = $Control/Book/RightPage/DetailPrompt
@onready var symbol_display = $Control/Book/RightPage/DetailPanel/SymbolDisplay
@onready var label_symbol_char = $Control/Book/RightPage/DetailPanel/LabelSymbolChar
@onready var decipher_choices = $Control/Book/RightPage/DetailPanel/DecipherChoices
@onready var label_result = $Control/Book/RightPage/DetailPanel/LabelResult

@onready var progress_label = $Control/Book/LeftPage/ProgressLabel

var selected_symbol: String = ""

func _ready() -> void:
	container.visible = false
	detail_panel.visible = false
	detail_prompt.visible = true
	
	Global.journal_toggled.connect(toggle_journal)
	list_discovered.item_selected.connect(_on_symbol_selected)
	
	# Setup match buttons
	for btn in decipher_choices.get_children():
		if btn is Button:
			btn.pressed.connect(func(): _on_choice_pressed(btn.text))

func toggle_journal(is_open: bool) -> void:
	if is_open:
		refresh_list()
		container.visible = true
		detail_panel.visible = false
		detail_prompt.visible = true
		selected_symbol = ""
	else:
		container.visible = false

func refresh_list() -> void:
	list_discovered.clear()
	
	if Global.discovered_symbols.is_empty():
		list_discovered.visible = false
		label_no_relics.visible = true
		progress_label.text = "Restorasi: 0/" + str(Global.total_sockets_in_level)
		return
		
	list_discovered.visible = true
	label_no_relics.visible = false
	
	for sym in Global.discovered_symbols:
		var item_text = "Prasasti '" + sym.to_upper() + "'"
		if Global.deciphered_symbols.has(sym):
			item_text += " (Terpecahkan)"
		else:
			item_text += " (Belum Diterjemahkan)"
		list_discovered.add_item(item_text)
		
	# Update progress counter
	var solved_count = Global.solved_sockets.size()
	progress_label.text = "Restorasi Soket: " + str(solved_count) + "/" + str(Global.total_sockets_in_level)

func _on_symbol_selected(index: int) -> void:
	selected_symbol = Global.discovered_symbols[index]
	detail_prompt.visible = false
	detail_panel.visible = true
	
	# Update procedural symbol draw
	if symbol_display.has_method("update_symbol"):
		symbol_display.update_symbol(selected_symbol)
		
	label_symbol_char.text = "Simbol Aksara: \"" + selected_symbol.to_upper() + "\""
	
	# Check if already deciphered
	if Global.deciphered_symbols.has(selected_symbol):
		show_deciphered_info()
	else:
		show_decipher_puzzle()

func show_deciphered_info() -> void:
	decipher_choices.visible = false
	label_result.visible = true
	
	var translation = Global.deciphered_symbols[selected_symbol]
	var clue = Global.dictionary[selected_symbol]["clue"]
	
	label_result.text = "TERJEMAHAN:\n\"" + translation + "\"\n\nPETUNJUK FISIK:\n" + clue
	label_result.add_theme_color_override("font_color", Global.COLOR_GOLD)

func show_decipher_puzzle() -> void:
	decipher_choices.visible = true
	label_result.visible = false
	label_result.text = ""
	
	# Randomize translation options
	var choices_nodes = decipher_choices.get_children()
	var all_words = []
	for k in Global.dictionary:
		all_words.append(Global.dictionary[k]["translation"])
		
	all_words.shuffle()
	
	for i in range(choices_nodes.size()):
		if i < all_words.size():
			choices_nodes[i].text = all_words[i]
			choices_nodes[i].visible = true
		else:
			choices_nodes[i].visible = false

func _on_choice_pressed(choice_text: String) -> void:
	if selected_symbol == "": return
	
	var correct_translation = Global.dictionary[selected_symbol]["translation"]
	
	if choice_text == correct_translation:
		# Correct decipher!
		Global.deciphered_symbols[selected_symbol] = choice_text
		Global.play_sfx.emit("decipher_success")
		Global.camera_shake.emit(1.0, 0.15)
		
		# Animate transition
		var tween = create_tween()
		label_result.visible = true
		label_result.text = "BERHASIL MENERJEMAHKAN!"
		label_result.add_theme_color_override("font_color", Global.COLOR_GOLD)
		decipher_choices.visible = false
		
		# Show translation info after brief delay
		tween.tween_interval(1.0)
		tween.tween_callback(func():
			show_deciphered_info()
			refresh_list()
		)
	else:
		# Wrong decipher
		Global.play_sfx.emit("decipher_fail")
		# Shake the detail panel slightly
		var original_pos = detail_panel.position
		var tween = create_tween()
		for i in range(4):
			tween.tween_property(detail_panel, "position", original_pos + Vector2(randf_range(-6, 6), 0), 0.05)
		tween.tween_property(detail_panel, "position", original_pos, 0.05)
