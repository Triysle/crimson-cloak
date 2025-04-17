extends Node

# Singleton reference, can be accessed from anywhere
var current_shrine: Node = null
var player: CharacterBody2D = null

# Door and scene transition variables
var active_door = null
var player_keys = []  # Simple array to hold keys for now

# Enemy tracking
var enemy_tracker = {}  # Dictionary to track enemies: { instance_id: { "scene": packed_scene, "position": Vector2 } }
var dead_enemies = []   # Array to store IDs of defeated enemies

func _ready():
	# Wait for level to be fully loaded
	await get_tree().process_frame
	await get_tree().process_frame
	
	# Find player
	player = get_tree().get_first_node_in_group("player")
	
	# Find all shrines
	connect_shrines()
	
	# Spawn player at initial shrine - with a slight delay
	call_deferred("spawn_player_at_initial_shrine")

func connect_shrines():
	var shrines = get_tree().get_nodes_in_group("shrine")
	
	for shrine in shrines:
		if not shrine.shrine_activated.is_connected(on_shrine_activated):
			shrine.shrine_activated.connect(on_shrine_activated.bind(shrine))

func spawn_player_at_initial_shrine():
	var shrines = get_tree().get_nodes_in_group("shrine")
	
	if shrines.size() > 0:
		# Use the first shrine as default
		var initial_shrine = shrines[0]
		
		# Set it as current shrine
		current_shrine = initial_shrine
		
		# Set shrine as active spawn point
		if initial_shrine.has_method("set_as_spawn_point"):
			initial_shrine.set_as_spawn_point()
		
		# Spawn player at shrine
		if player:
			# Don't set position directly, just call respawn_at
			player.respawn_at(initial_shrine.global_position)
	else:
		print("No shrines found in the level!")

func on_shrine_activated(shrine):
	# Update current shrine
	current_shrine = shrine
	
	# Respawn all dead enemies when a shrine is activated
	respawn_all_enemies()

# Function to respawn player at last activated shrine
func respawn_player():
	if current_shrine && player:
		# Respawn all dead enemies
		respawn_all_enemies()
		
		# Respawn player at shrine
		player.respawn_at(current_shrine.global_position)

# Function to register an enemy with the tracker
func register_enemy(enemy: Node):
	# Store enemy's original scene path and spawn position
	var enemy_data = {
		"scene": enemy.scene_file_path,
		"position": enemy.global_position,
		"properties": {}  # This could store additional enemy properties if needed
	}
	
	# Store in the dictionary with instance ID as key
	enemy_tracker[enemy.get_instance_id()] = enemy_data
	
	# Connect to the enemy's tree_exiting signal to handle cleanup
	if !enemy.tree_exiting.is_connected(_on_enemy_tree_exiting):
		enemy.tree_exiting.connect(_on_enemy_tree_exiting.bind(enemy))

# Called when an enemy is removed from the scene tree
func _on_enemy_tree_exiting(enemy: Node):
	var instance_id = enemy.get_instance_id()
	
	# Add to dead_enemies list if it was in our tracker
	if enemy_tracker.has(instance_id):
		dead_enemies.append(instance_id)

# Function to respawn all dead enemies
func respawn_all_enemies():
	# Process all dead enemies
	for enemy_id in dead_enemies:
		if enemy_tracker.has(enemy_id):
			var enemy_data = enemy_tracker[enemy_id]
			
			# Load the enemy scene
			var enemy_scene = load(enemy_data["scene"])
			if enemy_scene:
				# Instance the enemy
				var new_enemy = enemy_scene.instantiate()
				
				# Set position
				new_enemy.global_position = enemy_data["position"]
				
				# Add to the current scene
				get_tree().current_scene.add_child(new_enemy)
				
				# Register the new enemy
				register_enemy(new_enemy)
	
	# Clear the dead enemies list
	dead_enemies.clear()

# Function to set the active door when player enters door area
func set_active_door(door):
	active_door = door

# Function to check if player has a specific key
func has_key(key_name):
	return key_name in player_keys

# Function to add a key to the player's inventory
func add_key(key_name):
	if not key_name in player_keys:
		player_keys.append(key_name)
		print("Obtained key: " + key_name)

# Function to handle scene transitions
func transition_to_scene(target_scene, target_door):
	print("Transitioning to " + target_scene + " at door " + target_door)
	
	# Create a black rect for fade effect
	var fade_rect = ColorRect.new()
	fade_rect.color = Color(0, 0, 0, 0)  # Start transparent
	fade_rect.size = get_viewport().get_visible_rect().size
	fade_rect.z_index = 100  # Make sure it's on top
	
	get_tree().get_root().add_child(fade_rect)
	
	# Fade out
	var tween = create_tween()
	tween.tween_property(fade_rect, "color", Color(0, 0, 0, 1), 0.5)
	
	# Wait for fade to complete then change scene
	await tween.finished
	
	# Change the scene
	get_tree().change_scene_to_file(target_scene)
	
	# Wait for the next frame to ensure the scene is loaded
	await get_tree().process_frame
	
	# Find the target door in the new scene
	var doors = get_tree().get_nodes_in_group("door")
	var spawn_position = Vector2.ZERO
	
	for door in doors:
		if door.door_name == target_door:
			spawn_position = door.global_position
			break
	
	# Find player and position them at the target door
	if player:
		player.global_position = spawn_position
	
	# Fade in
	tween = create_tween()
	tween.tween_property(fade_rect, "color", Color(0, 0, 0, 0), 0.5)
	
	# Remove the fade rect when done
	await tween.finished
	fade_rect.queue_free()
