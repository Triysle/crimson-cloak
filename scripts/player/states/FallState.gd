extends State

func enter():
	player.animation_player.play("fall")

func physics_update(delta):
	# Skip input processing if player can't be controlled
	if not player.can_control:
		return
		
	# Apply gravity
	player.velocity.y += player.gravity * delta
	
	# Get the input direction early to use throughout the function
	var direction = Input.get_axis("move_left", "move_right")
	
	# Transition to idle or run when landing
	if player.is_on_floor():
		player.can_double_jump = false  # Reset double jump when landing
		if abs(direction) > 0.1:
			state_machine.transition_to("run")
		else:
			state_machine.transition_to("idle")
		return
	
	# Check for double jump input
	if Input.is_action_just_pressed("jump") and player.can_double_jump:
		player.can_double_jump = false  # Prevent more than one double jump
		state_machine.transition_to("doublejump")
		return
	
	if direction != 0:
		# Apply acceleration (but slightly reduced in air)
		player.velocity.x = move_toward(player.velocity.x, direction * player.speed * 0.8, player.acceleration * delta * 0.8)
		
		# Update player facing direction
		if direction > 0:
			player.sprite.flip_h = false
		elif direction < 0:
			player.sprite.flip_h = true
	else:
		# Apply air friction (less than ground friction)
		player.velocity.x = move_toward(player.velocity.x, 0, player.friction * delta * 0.3)
	
	# Handle attack input in mid-air
	if Input.is_action_just_pressed("attack"):
		state_machine.transition_to("attack")
		return
	
	# Apply movement
	player.move_and_slide()
