extends State

var climb_speed = 100.0  # Vertical climbing speed
var reaching_top = false  # Flag to indicate player is reaching the top
var current_ladder = null  # Reference to the ladder being climbed
var at_ladder_bottom = false  # Flag to check if we're at the bottom of a ladder

func enter():
	player.animation_player.play("climb_idle")
	
	# Stop all movement initially
	player.velocity = Vector2.ZERO
	
	# Disable gravity while climbing
	player.gravity_enabled = false
	
	# Check if we need to align player to ladder
	if current_ladder:
		# Center player horizontally on the ladder
		player.global_position.x = current_ladder.global_position.x
	
	# Check if we're at the bottom of the ladder
	check_ladder_bottom()

func exit():
	# Re-enable gravity
	player.gravity_enabled = true
	
	# Reset flags
	reaching_top = false
	at_ladder_bottom = false

func physics_update(_delta):
	# Skip input processing if player can't be controlled
	if not player.can_control:
		return
	
	# Handle vertical movement
	var vertical_input = Input.get_axis("move_up", "move_down")
	
	if vertical_input != 0:
		# Set vertical velocity based on input
		player.velocity.y = vertical_input * climb_speed
		
		# Play climb animation if moving
		if not reaching_top:
			player.animation_player.play("climb")
	else:
		# No input, stop vertical movement
		player.velocity.y = 0
		
		# Play idle climbing animation if not reaching top
		if not reaching_top:
			player.animation_player.play("climb_idle")
	
	# No horizontal movement while climbing
	player.velocity.x = 0
	
	# Check if player has reached the top of the ladder
	if check_ladder_top() and vertical_input < 0:  # Moving up and reached top
		# Start the climb_end animation
		if not reaching_top:
			reaching_top = true
			player.animation_player.play("climb_end")
			# Connect signal to know when animation is done if not already connected
			if not player.animation_player.animation_finished.is_connected(_on_climb_end_finished):
				player.animation_player.animation_finished.connect(_on_climb_end_finished)
			return
	
	# Check if player wants to exit ladder at the bottom
	if at_ladder_bottom and vertical_input > 0:  # Moving down at bottom
		state_machine.transition_to("idle")
		return
	
	# Handle jumping off the ladder
	if Input.is_action_just_pressed("jump"):
		player.velocity.y = player.jump_velocity
		
		# Add slight horizontal velocity based on input
		var horizontal_input = Input.get_axis("move_left", "move_right")
		if horizontal_input != 0:
			player.velocity.x = horizontal_input * player.speed * 0.5
		
		state_machine.transition_to("jump")
		return
	
	# Apply movement
	player.move_and_slide()
	
	# Update ladder bottom check
	check_ladder_bottom()

func _on_climb_end_finished(anim_name):
	if anim_name == "climb_end":
		# Disconnect the signal to avoid multiple connections
		if player.animation_player.animation_finished.is_connected(_on_climb_end_finished):
			player.animation_player.animation_finished.disconnect(_on_climb_end_finished)
		
		# Move player to the top of the ladder platform
		var ladder_top = current_ladder.global_position.y - current_ladder.get_node("CollisionShape2D").shape.extents.y
		player.global_position.y = ladder_top - 16  # Adjust based on player's height
		
		# Transition to idle state
		state_machine.transition_to("idle")

# Check if player is at the top of the ladder
func check_ladder_top() -> bool:
	if not current_ladder:
		return false
	
	# Get ladder's top position (assuming ladder has a CollisionShape2D)
	var ladder_shape = current_ladder.get_node("CollisionShape2D")
	if not ladder_shape:
		return false
		
	var ladder_top = current_ladder.global_position.y - ladder_shape.shape.extents.y
	
	# Check if player is at or above ladder's top
	return player.global_position.y <= ladder_top

# Check if player is at the bottom of the ladder
func check_ladder_bottom() -> bool:
	if not current_ladder:
		at_ladder_bottom = false
		return false
	
	# Get ladder's bottom position
	var ladder_shape = current_ladder.get_node("CollisionShape2D")
	if not ladder_shape:
		at_ladder_bottom = false
		return false
		
	var ladder_bottom = current_ladder.global_position.y + ladder_shape.shape.extents.y
	
	# Check if player is at or below ladder's bottom
	at_ladder_bottom = player.global_position.y >= ladder_bottom - 16  # Adjust based on player's feet position
	return at_ladder_bottom

# Set the current ladder being climbed
func set_ladder(ladder):
	current_ladder = ladder
