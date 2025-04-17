extends Node

# Currency
var currency: int = 0

# Items
var keys = []  # Array of key IDs for door access
var fragments = []  # Array of collected fragments
var collectibles = {}  # Dictionary of other collectibles

# Player reference
var player = null

# References to other managers
var player_manager = null

func _ready():
	# Wait for level to be fully loaded
	await get_tree().process_frame
	
	# Find references to other managers
	player_manager = get_node("/root/PlayerManager")
	
	# Find player
	player = get_tree().get_first_node_in_group("player")

# Function to add currency
func add_currency(amount: int):
	currency += amount
	print("Added ", amount, " currency! Total: ", currency)
	
	# Update player HUD if available
	if player and player.hud:
		player.hud.update_currency(currency)
	
	return currency

# Function to spend currency
func spend_currency(amount: int) -> bool:
	if currency >= amount:
		currency -= amount
		print("Spent ", amount, " currency! Remaining: ", currency)
		
		# Update player HUD if available
		if player and player.hud:
			player.hud.update_currency(currency)
		
		return true
	else:
		print("Not enough currency! Have: ", currency, ", need: ", amount)
		return false

# Function to add a key
func add_key(key_id: String):
	if not key_id in keys:
		keys.append(key_id)
		print("Added key: ", key_id)
	
	return keys

# Function to check if player has a key
func has_key(key_id: String) -> bool:
	return key_id in keys

# Function to add a fragment
func add_fragment(fragment_id: String):
	if not fragment_id in fragments:
		fragments.append(fragment_id)
		print("Added fragment: ", fragment_id)
		
		# Check if all fragments collected
		check_all_fragments_collected()
	
	return fragments

# Function to check if all fragments are collected
func check_all_fragments_collected():
	# This would depend on your game design
	# For now, just a placeholder that checks if we have 5 fragments
	if fragments.size() == 5:
		print("All fragments collected! Unlock final area or special ability.")
		# Implement special unlock logic here

# Function to add a collectible item
func add_collectible(item_id: String, item_data = null):
	collectibles[item_id] = item_data
	print("Added collectible: ", item_id)
	
	return collectibles

# Function to check if player has a collectible
func has_collectible(item_id: String) -> bool:
	return item_id in collectibles

# Function to get collectible data
func get_collectible(item_id: String):
	if has_collectible(item_id):
		return collectibles[item_id]
	return null
