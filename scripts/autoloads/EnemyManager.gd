extends Node

# Enemy tracking
var enemy_tracker = {}  # Dictionary to track enemies: { instance_id: { "scene": packed_scene, "position": Vector2 } }
var dead_enemies = []   # Array to store IDs of defeated enemies

# Enemy difficulty scaling
var difficulty_level = 1
var difficulty_multipliers = {
	"health": 1.0,
	"damage": 1.0,
	"speed": 1.0
}

# References to other managers
var level_manager = null

func _ready():
	# Wait for level to be fully loaded
	await get_tree().process_frame
	
	# Find references to other managers
	level_manager = get_node("/root/LevelManager")

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
	
	# Apply difficulty modifiers if needed
	apply_difficulty_modifiers(enemy)

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
				
				# Apply any stored properties or customizations
				for property_name in enemy_data["properties"].keys():
					if new_enemy.has_property(property_name):
						new_enemy.set(property_name, enemy_data["properties"][property_name])
				
				# Register the new enemy
				register_enemy(new_enemy)
	
	# Clear the dead enemies list
	dead_enemies.clear()

# Apply difficulty modifiers to enemy
func apply_difficulty_modifiers(enemy: Node):
	if "max_health" in enemy:
		enemy.max_health = int(enemy.max_health * difficulty_multipliers["health"])
		enemy.health = enemy.max_health
	
	if "damage" in enemy:
		enemy.damage = int(enemy.damage * difficulty_multipliers["damage"])
	
	if "movement_speed" in enemy:
		enemy.movement_speed = enemy.movement_speed * difficulty_multipliers["speed"]

# Increase difficulty level
func increase_difficulty(level_increment: int = 1):
	difficulty_level += level_increment
	
	# Update difficulty multipliers
	difficulty_multipliers["health"] = 1.0 + (difficulty_level - 1) * 0.1  # +10% per level
	difficulty_multipliers["damage"] = 1.0 + (difficulty_level - 1) * 0.1  # +10% per level
	difficulty_multipliers["speed"] = 1.0 + (difficulty_level - 1) * 0.05  # +5% per level
	
	print("Difficulty increased to level ", difficulty_level)
	print("New multipliers: ", difficulty_multipliers)

# Get enemies in radius around a position
func get_enemies_in_radius(position: Vector2, radius: float) -> Array:
	var result = []
	var enemies = get_tree().get_nodes_in_group("enemy")
	
	for enemy in enemies:
		if enemy.global_position.distance_to(position) <= radius:
			result.append(enemy)
	
	return result
