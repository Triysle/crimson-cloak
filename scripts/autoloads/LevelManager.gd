extends Node

# Door and scene transition variables
var active_door = null
var current_shrine = null

# References to other managers
var player_manager = null
var enemy_manager = null
var inventory_manager = null

# Reference to the player for convenience
var player = null

func _ready():
	# Wait for level to be fully loaded
	await get_tree().process_frame
	
	# Connect to other managers
	player_manager = get_node("/root/PlayerManager")
	enemy_manager = get_node("/root/EnemyManager")
	inventory_manager = get_node("/root/InventoryManager")
	
	# Find player
	player = get_tree().get_first_node_in_group("player")
	
	# Find all shrines
	connect_shrines()
	
	# Spawn player at initial shrine
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
		if player and player_manager:
			player_manager.respawn_player_at(initial_shrine.global_position)
	else:
		print("No shrines found in the level!")

func on_shrine_activated(shrine):
	# Update current shrine
	current_shrine = shrine
	
	# Respawn all dead enemies when a shrine is activated
	if enemy_manager:
		enemy_manager.respawn_all_enemies()

# Function to set the active door when player enters door area
func set_active_door(door):
	active_door = door

# Function to get the current active shrine
func get_current_shrine():
	return current_shrine

# Function to handle scene transitions
func transition_to_scene(target_scene, target_door_id):
	print("Transitioning to " + target_scene + " at door " + target_door_id)
	
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
	await get_tree().process_frame  # Wait one more frame to be sure
	
	# Find the target door in the new scene
	var doors = get_tree().get_nodes_in_group("door")
	var spawn_position = Vector2.ZERO
	var target_door = null
	
	for door in doors:
		if door.door_name == target_door_id:
			target_door = door
			# Get the spawn position from the door's spawn point
			spawn_position = door.get_spawn_position()
			break
	
	if target_door == null:
		print("ERROR: Could not find door with name " + target_door_id)
	
	# Find player and position them at the target door's spawn point
	player = get_tree().get_first_node_in_group("player")
	if player and player_manager:
		player.global_position = spawn_position
		
		# Handle the camera positioning
		var camera = player.get_node("Camera2D")
		if camera:
			# Disable smoothing
			var smoothing_enabled = camera.position_smoothing_enabled
			camera.position_smoothing_enabled = false
			
			# Force camera update
			camera.reset_smoothing()
			
			# Schedule re-enabling smoothing after a short delay
			await get_tree().create_timer(0.1).timeout
			camera.position_smoothing_enabled = smoothing_enabled
	else:
		print("ERROR: Could not find player")
	
	# Fade in
	tween = create_tween()
	tween.tween_property(fade_rect, "color", Color(0, 0, 0, 0), 0.5)
	
	# Remove the fade rect when done
	await tween.finished
	fade_rect.queue_free()
