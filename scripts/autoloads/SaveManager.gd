extends Node

# Save data constants
const SAVE_DIR = "user://saves/"
const SAVE_FILE_EXTENSION = ".json"

# Current save data
var current_save_slot = 1
var save_data = {}

# References to other managers
var level_manager = null
var player_manager = null
var enemy_manager = null
var inventory_manager = null

func _ready():
	# Create saves directory if it doesn't exist
	if not DirAccess.dir_exists_absolute(SAVE_DIR):
		DirAccess.make_dir_recursive_absolute(SAVE_DIR)
	
	# Wait for level to be fully loaded
	await get_tree().process_frame
	
	# Find references to other managers
	level_manager = get_node("/root/LevelManager")
	player_manager = get_node("/root/PlayerManager") 
	enemy_manager = get_node("/root/EnemyManager")
	inventory_manager = get_node("/root/InventoryManager")

# Save the game (called by shrines or other save points)
func save_game(slot: int = -1):
	if slot >= 0:
		current_save_slot = slot
	
	# Initialize save data
	save_data = {
		"version": "1.0",
		"timestamp": Time.get_unix_time_from_system(),
		"player": {},
		"level": {},
		"inventory": {},
		"settings": {}
	}
	
	# Collect save data from managers
	collect_player_data()
	collect_level_data()
	collect_inventory_data()
	
	# Write to file
	var save_path = SAVE_DIR + "save_" + str(current_save_slot) + SAVE_FILE_EXTENSION
	var file = FileAccess.open(save_path, FileAccess.WRITE)
	
	if file:
		file.store_string(JSON.stringify(save_data))
		print("Game saved to slot ", current_save_slot)
		return true
	else:
		print("Failed to save game!")
		return false

# Load the game
func load_game(slot: int = -1):
	if slot >= 0:
		current_save_slot = slot
	
	# Read from file
	var save_path = SAVE_DIR + "save_" + str(current_save_slot) + SAVE_FILE_EXTENSION
	
	if not FileAccess.file_exists(save_path):
		print("No save file found at slot ", current_save_slot)
		return false
	
	var file = FileAccess.open(save_path, FileAccess.READ)
	if not file:
		print("Failed to open save file!")
		return false
	
	var json_string = file.get_as_text()
	var json = JSON.new()
	var parse_result = json.parse(json_string)
	
	if parse_result != OK:
		print("Failed to parse save data!")
		return false
	
	save_data = json.data
	
	# Apply save data to managers
	apply_player_data()
	apply_level_data()
	apply_inventory_data()
	
	print("Game loaded from slot ", current_save_slot)
	return true

# Collect player data
func collect_player_data():
	if player_manager:
		var player = get_tree().get_first_node_in_group("player")
		if player:
			save_data["player"] = {
				"health": player.health,
				"max_health": player.max_health,
				"healing_charges": player.healing_charges,
				"max_healing_charges": player.max_healing_charges,
				"abilities": player_manager.collected_abilities,
				"health_upgrades": player_manager.health_upgrades,
				"healing_charge_upgrades": player_manager.healing_charge_upgrades
			}

# Collect level data
func collect_level_data():
	if level_manager:
		save_data["level"] = {
			"current_scene": get_tree().current_scene.scene_file_path,
			"current_shrine": level_manager.current_shrine.name if level_manager.current_shrine else ""
		}

# Collect inventory data
func collect_inventory_data():
	if inventory_manager:
		save_data["inventory"] = {
			"currency": inventory_manager.currency,
			"keys": inventory_manager.keys,
			"fragments": inventory_manager.fragments,
			"collectibles": inventory_manager.collectibles
		}

# Apply player data
func apply_player_data():
	if player_manager and "player" in save_data:
		var player_data = save_data["player"]
		var player = get_tree().get_first_node_in_group("player")
		
		if player:
			player.max_health = player_data["max_health"]
			player.health = player_data["health"]
			player.max_healing_charges = player_data["max_healing_charges"]
			player.healing_charges = player_data["healing_charges"]
			
			# Update HUD
			if player.hud:
				player.hud.update_health(player.health, player.max_health)
				player.hud.update_healing_charges(player.healing_charges, player.max_healing_charges)
		
		# Apply ability unlocks
		if "abilities" in player_data:
			player_manager.collected_abilities = player_data["abilities"]
		
		if "health_upgrades" in player_data:
			player_manager.health_upgrades = player_data["health_upgrades"]
			
		if "healing_charge_upgrades" in player_data:
			player_manager.healing_charge_upgrades = player_data["healing_charge_upgrades"]

# Apply level data
func apply_level_data():
	if level_manager and "level" in save_data:
		var level_data = save_data["level"]
		
		# Change to the saved scene if different from current
		if "current_scene" in level_data and level_data["current_scene"] != get_tree().current_scene.scene_file_path:
			get_tree().change_scene_to_file(level_data["current_scene"])
			
			# Wait for scene change
			await get_tree().process_frame
			await get_tree().process_frame
		
		# Activate saved shrine
		if "current_shrine" in level_data and level_data["current_shrine"] != "":
			var shrine_name = level_data["current_shrine"]
			var shrines = get_tree().get_nodes_in_group("shrine")
			
			for shrine in shrines:
				if shrine.name == shrine_name:
					level_manager.current_shrine = shrine
					shrine.set_as_spawn_point()
					break

# Apply inventory data
func apply_inventory_data():
	if inventory_manager and "inventory" in save_data:
		var inventory_data = save_data["inventory"]
		
		if "currency" in inventory_data:
			inventory_manager.currency = inventory_data["currency"]
			
			# Update HUD
			var player = get_tree().get_first_node_in_group("player")
			if player and player.hud:
				player.hud.update_currency(inventory_manager.currency)
		
		if "keys" in inventory_data:
			inventory_manager.keys = inventory_data["keys"]
			
		if "fragments" in inventory_data:
			inventory_manager.fragments = inventory_data["fragments"]
			
		if "collectibles" in inventory_data:
			inventory_manager.collectibles = inventory_data["collectibles"]

# Check if a save exists
func save_exists(slot: int) -> bool:
	var save_path = SAVE_DIR + "save_" + str(slot) + SAVE_FILE_EXTENSION
	return FileAccess.file_exists(save_path)

# Delete a save
func delete_save(slot: int) -> bool:
	var save_path = SAVE_DIR + "save_" + str(slot) + SAVE_FILE_EXTENSION
	
	if FileAccess.file_exists(save_path):
		var dir = DirAccess.open(SAVE_DIR)
		if dir:
			dir.remove(save_path.get_file())
			print("Save file deleted: ", slot)
			return true
	
	print("No save file found to delete: ", slot)
	return false

# Get save metadata (for save slot UI)
func get_save_metadata(slot: int) -> Dictionary:
	var save_path = SAVE_DIR + "save_" + str(slot) + SAVE_FILE_EXTENSION
	
	if not FileAccess.file_exists(save_path):
		return {}
	
	var file = FileAccess.open(save_path, FileAccess.READ)
	if not file:
		return {}
	
	var json_string = file.get_as_text()
	var json = JSON.new()
	var parse_result = json.parse(json_string)
	
	if parse_result != OK:
		return {}
	
	var data = json.data
	
	# Return minimal metadata for UI display
	var metadata = {
		"exists": true,
		"timestamp": data["timestamp"] if "timestamp" in data else 0,
		"playtime": data["settings"]["playtime"] if "settings" in data and "playtime" in data["settings"] else 0,
		"player_health": data["player"]["health"] if "player" in data and "health" in data["player"] else 0,
		"player_max_health": data["player"]["max_health"] if "player" in data and "max_health" in data["player"] else 0,
		"fragments_collected": data["inventory"]["fragments"].size() if "inventory" in data and "fragments" in data["inventory"] else 0,
		"currency": data["inventory"]["currency"] if "inventory" in data and "currency" in data["inventory"] else 0
	}
	
	return metadata
