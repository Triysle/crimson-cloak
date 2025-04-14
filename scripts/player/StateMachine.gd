class_name StateMachine
extends Node

# Node references
var player
var current_state: State

# Dictionary to store all the states
var states = {}

func _ready():
	# Wait until the next frame to ensure player is fully initialized
	await get_tree().process_frame
	
	# Get the player reference
	player = get_parent()
	
	# Initialize states
	for child in get_children():
		if child is State:
			states[child.name.to_lower()] = child
			child.state_machine = self
			child.player = player
	
	# Set initial state
	if states.has("idle"):
		current_state = states["idle"]
		current_state.enter()

	print("Available states: ", states.keys())
	
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
	state_name = state_name.to_lower()
	
	# Check if current_state exists and the name matches
	if current_state and state_name == current_state.name.to_lower():
		return
	
	# Debug the state transition
	print("Trying to transition to state:", state_name)
	print("Available states:", states.keys())
	
	if states.has(state_name):
		if current_state:
			current_state.exit()
		
		current_state = states[state_name]
		print("Successfully transitioned to state:", current_state.name)
		current_state.enter()
	else:
		print("State '", state_name, "' not found in state machine. Available states:", states.keys())
