extends Node

# Singleton reference, can be accessed from anywhere
var current_shrine: Node = null
var player: CharacterBody2D = null

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
