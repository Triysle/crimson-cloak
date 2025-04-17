extends Node

signal dialog_started
signal dialog_ended
signal dialog_option_selected(option_id)

# Dialog state
var is_dialog_active = false
var current_dialog_id = ""
var current_dialog_node = 0
var dialog_history = []

# Dialog data storage
var dialog_data = {}
var npc_data = {}

# Reference to dialog UI
var dialog_ui = null

# References to other managers
var inventory_manager = null
var player_manager = null

func _ready():
	# Wait for level to be fully loaded
	await get_tree().process_frame
	
	# Find references to other managers
	inventory_manager = get_node("/root/InventoryManager")
	player_manager = get_node("/root/PlayerManager")
	
	# Preload dialog data
	preload_dialog_data()

# Preload dialog data from JSON files
func preload_dialog_data():
	# You would typically load these from files
	# For now, initialize with empty data
	dialog_data = {}
	npc_data = {}
	
	# Example loading code (uncomment and modify when you have actual dialog files)
	# var dialog_file = FileAccess.open("res://data/dialog.json", FileAccess.READ)
	# if dialog_file:
	#     var json_string = dialog_file.get_as_text()
	#     var json = JSON.new()
	#     var parse_result = json.parse(json_string)
	#     if parse_result == OK:
	#         dialog_data = json.data

# Start a dialog with an NPC
func start_dialog(npc_id: String, dialog_id: String = ""):
	# If dialog_id not specified, get default dialog for this NPC
	if dialog_id == "" and npc_id in npc_data:
		dialog_id = npc_data[npc_id].default_dialog
	
	# Validate dialog exists
	if not dialog_id in dialog_data:
		print("Dialog not found: ", dialog_id)
		return false
	
	# Setup dialog state
	current_dialog_id = dialog_id
	current_dialog_node = 0
	is_dialog_active = true
	dialog_history.clear()
	
	# Find or create dialog UI
	if dialog_ui == null:
		dialog_ui = get_tree().get_first_node_in_group("dialog_ui")
		if dialog_ui == null:
			# Create dialog UI if not found
			dialog_ui = load("res://scenes/ui/DialogUI.tscn").instantiate()
			get_tree().current_scene.add_child(dialog_ui)
	
	# Set portrait and name in UI
	if npc_id in npc_data:
		dialog_ui.set_speaker_name(npc_data[npc_id].name)
		dialog_ui.set_portrait(npc_data[npc_id].portrait)
	
	# Show first dialog node
	show_dialog_node(0)
	
	# Emit signal
	dialog_started.emit()
	
	return true

# Show a specific dialog node
func show_dialog_node(node_index: int):
	if not current_dialog_id in dialog_data:
		end_dialog()
		return
	
	var dialog = dialog_data[current_dialog_id]
	if node_index >= dialog.nodes.size():
		end_dialog()
		return
	
	# Store current node in history
	dialog_history.append(node_index)
	current_dialog_node = node_index
	
	var node = dialog.nodes[node_index]
	
	# Display text in UI
	dialog_ui.set_dialog_text(node.text)
	
	# Handle options if present
	if "options" in node and node.options.size() > 0:
		var valid_options = []
		
		# Process conditions for each option
		for option in node.options:
			var is_valid = true
			
			# Check requirements
			if "requirements" in option:
				for req in option.requirements:
					match req.type:
						"has_item":
							if not inventory_manager or not inventory_manager.has_collectible(req.item_id):
								is_valid = false
						"has_fragment":
							if not inventory_manager or not req.fragment_id in inventory_manager.fragments:
								is_valid = false
						"has_ability":
							if not player_manager or not player_manager.has_ability(req.ability_id):
								is_valid = false
						"currency":
							if not inventory_manager or inventory_manager.currency < req.amount:
								is_valid = false
			
			if is_valid:
				valid_options.append({
					"id": option.id,
					"text": option.text
				})
		
		# Show options in UI
		dialog_ui.show_options(valid_options)
	else:
		# No options, just continue button
		dialog_ui.hide_options()
		dialog_ui.show_continue_button()

# Process player's selection of a dialog option
func select_option(option_id):
	if not is_dialog_active:
		return
	
	var dialog = dialog_data[current_dialog_id]
	var node = dialog.nodes[current_dialog_node]
	
	# Find the selected option
	var selected_option = null
	for option in node.options:
		if option.id == option_id:
			selected_option = option
			break
	
	if selected_option == null:
		return
	
	# Process option effects
	if "effects" in selected_option:
		process_dialog_effects(selected_option.effects)
	
	# Emit signal for option selected
	dialog_option_selected.emit(option_id)
	
	# Go to next node
	if "next_node" in selected_option:
		show_dialog_node(selected_option.next_node)
	else:
		end_dialog()

# Continue to next dialog node
func continue_dialog():
	if not is_dialog_active:
		return
	
	var dialog = dialog_data[current_dialog_id]
	var node = dialog.nodes[current_dialog_node]
	
	# Process node effects if any
	if "effects" in node:
		process_dialog_effects(node.effects)
	
	# Go to next node if specified
	if "next_node" in node:
		show_dialog_node(node.next_node)
	else:
		end_dialog()

# Process dialog effects (items, quests, etc.)
func process_dialog_effects(effects):
	for effect in effects:
		match effect.type:
			"give_item":
				if inventory_manager:
					inventory_manager.add_collectible(effect.item_id, effect.item_data if "item_data" in effect else null)
			"remove_item":
				if inventory_manager and inventory_manager.collectibles.has(effect.item_id):
					inventory_manager.collectibles.erase(effect.item_id)
			"give_currency":
				if inventory_manager:
					inventory_manager.add_currency(effect.amount)
			"take_currency":
				if inventory_manager:
					inventory_manager.spend_currency(effect.amount)
			"unlock_ability":
				if player_manager:
					player_manager.unlock_ability(effect.ability_id)
			"heal_player":
				var player = get_tree().get_first_node_in_group("player")
				if player and player.has_method("heal_to_full"):
					player.heal_to_full()
			"start_quest":
				# Quest system to be implemented
				print("Starting quest: ", effect.quest_id)
			"complete_quest":
				# Quest system to be implemented
				print("Completing quest: ", effect.quest_id)
			"change_dialog":
				current_dialog_id = effect.dialog_id
				show_dialog_node(effect.node_id if "node_id" in effect else 0)
				return

# End current dialog
func end_dialog():
	is_dialog_active = false
	current_dialog_id = ""
	current_dialog_node = 0
	
	# Hide dialog UI
	if dialog_ui:
		dialog_ui.hide()
	
	# Emit signal
	dialog_ended.emit()

# Add or update dialog data
func add_dialog(dialog_id: String, dialog: Dictionary):
	dialog_data[dialog_id] = dialog

# Add or update NPC data
func add_npc(npc_id: String, npc: Dictionary):
	npc_data[npc_id] = npc

# Input handling (call this from _input in main scene)
func handle_input(event):
	if not is_dialog_active:
		return false
	
	if event is InputEventKey:
		if event.pressed:
			if event.keycode == KEY_SPACE:
				continue_dialog()
				return true
	
	return false
