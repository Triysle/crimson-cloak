extends Node

signal purchase_completed(item_id)
signal purchase_failed(item_id, reason)

# Shop data
var shop_data = {}
var current_shop_id = ""
var current_shop_inventory = []

# Reference to shop UI
var shop_ui = null

# References to other managers
var inventory_manager = null
var player_manager = null
var dialog_manager = null

func _ready():
	# Wait for level to be fully loaded
	await get_tree().process_frame
	
	# Find references to other managers
	inventory_manager = get_node("/root/InventoryManager")
	player_manager = get_node("/root/PlayerManager")
	dialog_manager = get_node("/root/DialogManager")
	
	# Preload shop data
	preload_shop_data()

# Preload shop data from JSON files
func preload_shop_data():
	# You would typically load these from files
	# For now, initialize with basic shop data
	shop_data = {
		"village_blacksmith": {
			"name": "Village Blacksmith",
			"shopkeeper": "blacksmith",
			"greeting_dialog": "blacksmith_greeting",
			"items": [
				{
					"id": "sword_upgrade",
					"name": "Sword Upgrade",
					"description": "Increases melee damage by 25%",
					"price": 150,
					"icon": "res://assets/ui/items/sword_upgrade.png",
					"type": "upgrade",
					"effect": {
						"type": "damage_multiplier",
						"value": 1.25
					},
					"requirements": []
				},
				{
					"id": "health_potion",
					"name": "Health Potion",
					"description": "Restores one healing charge",
					"price": 50,
					"icon": "res://assets/ui/items/health_potion.png",
					"type": "consumable",
					"effect": {
						"type": "healing_charge",
						"value": 1
					},
					"requirements": []
				}
			]
		},
		"village_alchemist": {
			"name": "Village Alchemist",
			"shopkeeper": "alchemist",
			"greeting_dialog": "alchemist_greeting",
			"items": [
				{
					"id": "health_upgrade",
					"name": "Heart Container",
					"description": "Increases maximum health by 20",
					"price": 200,
					"icon": "res://assets/ui/items/heart_container.png",
					"type": "upgrade",
					"effect": {
						"type": "max_health",
						"value": 20
					},
					"requirements": []
				},
				{
					"id": "stamina_upgrade",
					"name": "Stamina Vial",
					"description": "Increases maximum healing charges by 1",
					"price": 250,
					"icon": "res://assets/ui/items/stamina_vial.png",
					"type": "upgrade",
					"effect": {
						"type": "max_healing_charges",
						"value": 1
					},
					"requirements": [
						{
							"type": "ability",
							"id": "slide"
						}
					]
				}
			]
		}
	}

# Open a shop with the given ID
func open_shop(shop_id: String):
	if not shop_id in shop_data:
		print("Shop not found: ", shop_id)
		return false
	
	current_shop_id = shop_id
	var shop = shop_data[shop_id]
	
	# Filter inventory based on requirements
	current_shop_inventory = []
	for item in shop.items:
		var can_show = true
		
		# Check requirements
		if "requirements" in item:
			for req in item.requirements:
				match req.type:
					"ability":
						if not player_manager or not player_manager.has_ability(req.id):
							can_show = false
					"item":
						if not inventory_manager or not inventory_manager.has_collectible(req.id):
							can_show = false
					"fragment":
						if not inventory_manager or not req.id in inventory_manager.fragments:
							can_show = false
		
		if can_show:
			current_shop_inventory.append(item)
	
	# Find or create shop UI
	if shop_ui == null:
		shop_ui = get_tree().get_first_node_in_group("shop_ui")
		if shop_ui == null:
			# Create shop UI if not found
			shop_ui = load("res://scenes/ui/ShopUI.tscn").instantiate()
			get_tree().current_scene.add_child(shop_ui)
	
	# Set shop name in UI
	shop_ui.set_shop_name(shop.name)
	
	# Show shop dialog if available
	if dialog_manager and "greeting_dialog" in shop:
		dialog_manager.start_dialog(shop.shopkeeper, shop.greeting_dialog)
		
		# Connect dialog ending to show shop
		if not dialog_manager.dialog_ended.is_connected(_on_dialog_ended):
			dialog_manager.dialog_ended.connect(_on_dialog_ended)
	else:
		# Show shop UI immediately if no dialog
		show_shop_ui()
	
	return true

# Function called when dialog ends
func _on_dialog_ended():
	# Show shop UI
	show_shop_ui()
	
	# Disconnect to avoid repeated callbacks
	if dialog_manager.dialog_ended.is_connected(_on_dialog_ended):
		dialog_manager.dialog_ended.disconnect(_on_dialog_ended)

# Show the shop UI with current inventory
func show_shop_ui():
	if shop_ui:
		# Display shop items
		shop_ui.display_items(current_shop_inventory)
		
		# Update currency display
		if inventory_manager:
			shop_ui.update_currency(inventory_manager.currency)
		
		# Show the UI
		shop_ui.show()

# Close the current shop
func close_shop():
	current_shop_id = ""
	current_shop_inventory = []
	
	# Hide shop UI
	if shop_ui:
		shop_ui.hide()

# Attempt to purchase an item
func purchase_item(item_id: String):
	# Find the item in current inventory
	var item = null
	for inv_item in current_shop_inventory:
		if inv_item.id == item_id:
			item = inv_item
			break
	
	if item == null:
		emit_signal("purchase_failed", item_id, "Item not available")
		return false
	
	# Check if player has enough currency
	if not inventory_manager or inventory_manager.currency < item.price:
		emit_signal("purchase_failed", item_id, "Not enough currency")
		return false
	
	# Process purchase based on item type
	var success = false
	
	match item.type:
		"upgrade":
			success = apply_upgrade(item)
		"consumable":
			success = apply_consumable(item)
		"key":
			success = add_key_item(item)
	
	if success:
		# Deduct currency
		inventory_manager.spend_currency(item.price)
		
		# Update currency display in UI
		if shop_ui:
			shop_ui.update_currency(inventory_manager.currency)
		
		# Emit signal
		emit_signal("purchase_completed", item_id)
		
		return true
	else:
		emit_signal("purchase_failed", item_id, "Could not apply item effect")
		return false

# Apply an upgrade item
func apply_upgrade(item):
	var effect = item.effect
	
	match effect.type:
		"max_health":
			if player_manager:
				player_manager.add_health_upgrade(effect.value)
				return true
		"max_healing_charges":
			if player_manager:
				player_manager.add_healing_charge_upgrade()
				return true
		"damage_multiplier":
			# Would require implementation in combat system
			print("Applied damage multiplier: ", effect.value)
			return true
	
	return false

# Apply a consumable item
func apply_consumable(item):
	var effect = item.effect
	var player = get_tree().get_first_node_in_group("player")
	
	match effect.type:
		"healing_charge":
			if player and player.has_method("add_healing_charge"):
				player.add_healing_charge(effect.value)
				return true
		"full_heal":
			if player and player.has_method("heal_to_full"):
				player.heal_to_full()
				return true
	
	return false

# Add a key item to inventory
func add_key_item(item):
	if inventory_manager:
		if item.effect.type == "key":
			inventory_manager.add_key(item.effect.key_id)
			return true
		elif item.effect.type == "collectible":
			inventory_manager.add_collectible(item.id, item.effect.data if "data" in item.effect else null)
			return true
	
	return false

# Add a new shop or update an existing one
func add_shop(shop_id: String, shop_data: Dictionary):
	shop_data[shop_id] = shop_data

# Add a new item to a shop
func add_shop_item(shop_id: String, item: Dictionary):
	if shop_id in shop_data:
		shop_data[shop_id].items.append(item)
		return true
	return false
