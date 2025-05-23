extends State

func enter():
	player.animation_player.play("idle")
	player.can_double_jump = false  # Reset double jump ability

func physics_update(delta):
	# Skip input processing if player can't be controlled
	if not player.can_control:
		return
		
	# Apply gravity
	if not player.is_on_floor():
		player.velocity.y += player.gravity * delta
		state_machine.transition_to("fall")
		return
	
	# Handle movement input
	var direction = Input.get_axis("move_left", "move_right")
	
	# Handle friction when no input
	player.velocity.x = move_toward(player.velocity.x, 0, player.friction * delta)
	
	# Transition to run state when moving
	if abs(direction) > 0.1:
		state_machine.transition_to("run")
		return
	
	# Check for crouch input
	if Input.is_action_just_pressed("move_down"):
		state_machine.transition_to("crouch")
		return
	
	# Check for block input
	if Input.is_action_just_pressed("block"):
		state_machine.transition_to("block")
		return
	
	# Check for ladder climbing
	if player.current_ladder and Input.is_action_pressed("move_up"):
		state_machine.transition_to("climb")
		return
	
	# Handle jump
	if Input.is_action_just_pressed("jump"):
		if Input.is_action_pressed("move_down") and player.is_on_floor():
			# Use Godot's built-in one-way collision dropping
			player.fall_through_platforms()
			state_machine.transition_to("fall")
		else:
			# Normal jump
			player.velocity.y = player.jump_velocity
			state_machine.transition_to("jump")
		return
	
	# Handle attack
	if Input.is_action_just_pressed("attack"):
		state_machine.transition_to("attack")
		return
	
	# Apply movement
	player.move_and_slide()
