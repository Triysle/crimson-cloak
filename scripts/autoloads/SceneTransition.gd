extends Node

# Track the last door used and the target door to spawn at
var last_door_name: String = ""
var target_door: String = ""

# Called when a scene is loaded
func _ready():
	call_deferred("_connect_to_scene_tree")

func _connect_to_scene_tree():
	# Wait for one frame to make sure the scene is fully loaded
	await get_tree().process_frame
	await get_tree().process_frame  # Sometimes a second wait is needed
	
	# Find the target door and position the player there
	if target_door != "":
		_position_player_at_door(target_door)

func _position_player_at_door(door_name: String):
	# Find all doors in the scene
	var doors = get_tree().get_nodes_in_group("door")
	
	# Find the matching door
	for door in doors:
		if door.door_name == door_name:
			# Find the player
			var player = get_tree().get_first_node_in_group("player")
			
			if player:
				# Position the player at the door
				player.global_position = door.global_position
				
				# We're done (but leave target_door set for the door's _ready function)
				return
	
	# If we didn't find the door, log a warning
	print("Warning: Could not find door named '" + door_name + "' in the current scene.")
