class_name EnemyStateMachine
extends Node

# Node references
var enemy
var current_state: EnemyState

# Dictionary to store all the states
var states = {}

func _ready():
	# Wait until the next frame to ensure enemy is fully initialized
	await get_tree().process_frame
	
	# Get the enemy reference
	enemy = get_parent()
	
	# Initialize states
	for child in get_children():
		if child is EnemyState:
			states[child.name.to_lower()] = child
			child.state_machine = self
			child.enemy = enemy
	
	# Set initial state
	if states.has("idle"):
		current_state = states["idle"]
		current_state.enter()

func _process(delta):
	if current_state:
		current_state.update(delta)

func _physics_process(delta):
	if current_state:
		current_state.physics_update(delta)

func _input(event):
	if current_state:
		current_state.handle_input(event)

# Function to change state
func transition_to(state_name: String):
	if state_name == current_state.name.to_lower():
		return
		
	if states.has(state_name):
		if current_state:
			current_state.exit()
		
		current_state = states[state_name]
		current_state.enter()
	else:
		print("State ", state_name, " not found in state machine")
