extends Node

# References to the new managers
var level_manager
var player_manager
var enemy_manager
var inventory_manager
var save_manager

# Keep some of the original variables for backward compatibility
var current_shrine = null
var player = null
var active_door = null
var player_keys = []
var enemy_tracker = {}
var dead_enemies = []

func _ready():
	print("NOTICE: Using GameManager compatibility layer - please update your code to use the new manager system")
	
	# Wait for a frame to ensure other autoloads are ready
	await get_tree().process_frame
	
	# Get references to other managers
	level_manager = get_node("/root/LevelManager")
	player_manager = get_node("/root/PlayerManager")
	enemy_manager = get_node("/root/EnemyManager")
	inventory_manager = get_node("/root/InventoryManager")
	save_manager = get_node("/root/SaveManager")
	
	# Find player reference
	player = get_tree().get_first_node_in_group("player")

# Function to register an enemy with the tracker (forward to EnemyManager)
func register_enemy(enemy: Node):
	enemy_manager.register_enemy(enemy)

# Function to respawn player at last activated shrine (forward to PlayerManager)
func respawn_player():
	player_manager.respawn_player()

# Function to check if player has a specific key (forward to InventoryManager)
func has_key(key_name):
	return inventory_manager.has_key(key_name)

# Function to add a key to the player's inventory (forward to InventoryManager)
func add_key(key_name):
	inventory_manager.add_key(key_name)

# Function to set the active door when player enters door area (forward to LevelManager)
func set_active_door(door):
	level_manager.set_active_door(door)

# Function to handle scene transitions (forward to LevelManager)
func transition_to_scene(target_scene, target_door_id):
	level_manager.transition_to_scene(target_scene, target_door_id)

# Function to respawn all dead enemies (forward to EnemyManager)
func respawn_all_enemies():
	enemy_manager.respawn_all_enemies()

# Forward current_shrine property
func _get_current_shrine():
	return level_manager.current_shrine

func _set_current_shrine(shrine):
	level_manager.current_shrine = shrine

# Forward player_keys property
func _get_player_keys():
	return inventory_manager.keys

func _set_player_keys(keys):
	inventory_manager.keys = keys

# Forward active_door property
func _get_active_door():
	return level_manager.active_door

func _set_active_door(door):
	level_manager.active_door = door

# Set up property forwarding
func _get_property_list():
	var properties = []
	properties.append({
		"name": "current_shrine",
		"type": TYPE_OBJECT,
		"usage": PROPERTY_USAGE_DEFAULT,
		"hint": PROPERTY_HINT_NONE
	})
	properties.append({
		"name": "player_keys",
		"type": TYPE_ARRAY,
		"usage": PROPERTY_USAGE_DEFAULT,
		"hint": PROPERTY_HINT_NONE
	})
	properties.append({
		"name": "active_door",
		"type": TYPE_OBJECT,
		"usage": PROPERTY_USAGE_DEFAULT,
		"hint": PROPERTY_HINT_NONE
	})
	return properties

# Override _get/_set methods to forward property access
func _get(property):
	match property:
		"current_shrine":
			return _get_current_shrine()
		"player_keys":
			return _get_player_keys()
		"active_door":
			return _get_active_door()
	return null

func _set(property, value):
	match property:
		"current_shrine":
			_set_current_shrine(value)
			return true
		"player_keys":
			_set_player_keys(value)
			return true
		"active_door":
			_set_active_door(value)
			return true
	return false
