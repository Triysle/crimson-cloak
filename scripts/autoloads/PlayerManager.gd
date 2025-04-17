extends Node

# Player references
var player: CharacterBody2D = null

# Default player stats (used for initialization and respawn)
var default_max_health: int = 100
var default_health: int = 100
var default_max_healing_charges: int = 5
var default_healing_charges: int = 1

# Track progression and upgrades
var collected_abilities = []
var health_upgrades = 0
var healing_charge_upgrades = 0

# References to other managers
var level_manager = null

func _ready():
	# Wait for level to be fully loaded
	await get_tree().process_frame
	
	# Find references to other managers
	level_manager = get_node("/root/LevelManager")
	
	# Find player
	player = get_tree().get_first_node_in_group("player")

# Function to respawn player at the last activated shrine
func respawn_player():
	var shrine = level_manager.get_current_shrine() if level_manager else null
	
	if shrine and player:
		respawn_player_at(shrine.global_position)

# Function to respawn player at a specific position
func respawn_player_at(spawn_position: Vector2):
	if player:
		# Reset player state
		reset_player_state()
		
		# Set player position to respawn point
		player.global_position = spawn_position
		
		# Transition to spawn state
		player.state_machine.transition_to("spawn")

# Reset player state for respawn
func reset_player_state():
	if player:
		player.health = player.max_health
		player.velocity = Vector2.ZERO
		player.can_control = false
		
		# Update HUD
		if player.hud:
			player.hud.update_health(player.health, player.max_health)

# Handle player death
func on_player_death():
	# This will be called from the player's die() function
	respawn_player()

# Add health upgrade
func add_health_upgrade(amount: int = 20):
	health_upgrades += 1
	
	if player:
		player.max_health += amount
		player.health += amount
		
		# Update HUD
		if player.hud:
			player.hud.update_health(player.health, player.max_health)

# Add healing charge upgrade
func add_healing_charge_upgrade():
	healing_charge_upgrades += 1
	
	if player:
		player.max_healing_charges += 1
		player.add_healing_charge(1)

# Register ability unlock
func unlock_ability(ability_name: String, ability_texture = null):
	if not ability_name in collected_abilities:
		collected_abilities.append(ability_name)
		
		# Update the player's ability icon if provided
		if player and ability_texture:
			player.set_ability(ability_texture)
			
	# Implement ability-specific unlock logic
	match ability_name:
		"double_jump":
			print("Double jump ability unlocked!")
			# Any specific logic for double jump unlock
		"slide":
			print("Slide ability unlocked!")
			# Any specific logic for slide unlock
		"air_attack":
			print("Air attack ability unlocked!")
			# Any specific logic for air attack unlock
		"block":
			print("Block ability unlocked!")
			# Any specific logic for block unlock
			
	return true

# Check if an ability is unlocked
func has_ability(ability_name: String) -> bool:
	return ability_name in collected_abilities
