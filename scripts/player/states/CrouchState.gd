extends State

func enter():
	player.animation_player.play("crouch")
	
	# Switch collision shapes
	player.get_node("NormalCollider").disabled = true
	player.get_node("CrouchCollider").disabled = false
	
	# Keep horizontal momentum but don't accelerate
	player.velocity.x = move_toward(player.velocity.x, 0, player.friction * 0.5)

func exit():
	# Switch back to normal collision shape
	player.get_node("NormalCollider").disabled = false
	player.get_node("CrouchCollider").disabled = true

func physics_update(delta):
	# Skip input processing if player can't be controlled
	if not player.can_control:
		return
		
	# Apply gravity
	if not player.is_on_floor():
		player.velocity.y += player.gravity * delta
	
	# Keep player movement minimal while crouching
	player.velocity.x = move_toward(player.velocity.x, 0, player.friction * delta)
	
	# Check if down is released to stand up
	if not Input.is_action_pressed("move_down"):
		# Check if we can stand up when on floor
		if not player.is_on_floor() or not is_blocked_above():
			if Input.is_action_pressed("block"):
				state_machine.transition_to("block")
			else:
				if player.is_on_floor():
					state_machine.transition_to("idle")
				else:
					state_machine.transition_to("fall")
		return
	
	# Check for block input while crouching
	if Input.is_action_just_pressed("block"):
		state_machine.transition_to("crouchblock")
		return
	
	# Check for fall-through platform
	if Input.is_action_just_pressed("jump"):
		if player.is_on_floor():
			player.fall_through_platforms()
		state_machine.transition_to("fall")
		return
		
	# Apply movement
	player.move_and_slide()

# Function to check if there's enough space to stand up
func is_blocked_above() -> bool:
	# Check if normal collider would intersect with something if enabled
	var normal_collider = player.get_node("NormalCollider")
	
	# Current position and rotation of the player
	var global_transform = player.global_transform
	
	# Create a direct space state query
	var space_state = player.get_world_2d().direct_space_state
	var query = PhysicsShapeQueryParameters2D.new()
	
	# Use the normal collider's shape
	query.set_shape(normal_collider.shape)
	query.transform = global_transform * normal_collider.transform
	
	# Only collide with the world layer
	query.collision_mask = 1  # Assuming world is on layer 1
	
	# Exclude the player itself
	query.exclude = [player]
	
	# Check for collisions
	var result = space_state.intersect_shape(query)
	
	# If we have any collisions, we can't stand up
	return result.size() > 0
