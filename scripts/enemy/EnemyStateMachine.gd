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
		enemy.current_state_name = "idle"
		enemy.debug_print("Initial state: idle")

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
	if not states.has(state_name.to_lower()):
		enemy.debug_print("ERROR: State " + state_name + " not found in state machine")
		return
		
	if current_state:
		if state_name.to_lower() == current_state.name.to_lower():
			return
		
		enemy.debug_print("Transitioning from " + current_state.name + " to " + state_name)
		# Debug velocity before state change
		enemy.debug_print("  -> Velocity before state change: " + str(enemy.velocity))
		
		current_state.exit()
	else:
		enemy.debug_print("Transitioning from null to " + state_name)
	
	current_state = states[state_name.to_lower()]
	enemy.current_state_name = state_name.to_lower()  # Update the tracking variable
	current_state.enter()
	
	# Debug velocity after state change
	enemy.debug_print("  -> Velocity after state change: " + str(enemy.velocity))
