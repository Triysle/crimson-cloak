extends Node

# Singleton reference, can be accessed from anywhere
var current_shrine: Node = null
var player: CharacterBody2D = null

func _ready():
	# Wait for level to be fully loaded
	await get_tree().process_frame
	
	# Find player
	player = get_tree().get_first_node_in_group("player")
	
	# Find all shrines
	connect_shrines()
	
	# Spawn player at initial shrine
	spawn_player_at_initial_shrine()

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
			player.global_position = initial_shrine.global_position
			player.respawn_at(initial_shrine.global_position)

func on_shrine_activated(shrine):
	# Update current shrine
	current_shrine = shrine

# Function to respawn player at last activated shrine
func respawn_player():
	if current_shrine && player:
		player.respawn_at(current_shrine.global_position)
