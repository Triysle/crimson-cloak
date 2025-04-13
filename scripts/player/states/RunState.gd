extends State

func enter():
	player.animation_player.play("run")

func physics_update(delta):
	# Skip input processing if player can't be controlled
	if not player.can_control:
		return
		
	# Apply gravity
	if not player.is_on_floor():
		player.velocity.y += player.gravity * delta
		state_machine.transition_to("fall")
		return
	
	# Get the input direction
	var direction = Input.get_axis("move_left", "move_right")
	
	if direction != 0:
		# Apply acceleration
		player.velocity.x = move_toward(player.velocity.x, direction * player.speed, player.acceleration * delta)
		
		# Update player facing direction
		if direction > 0:
			player.sprite.flip_h = false
		elif direction < 0:
			player.sprite.flip_h = true
			
		# Check for slide input - only allow sliding if we have some speed
		if Input.is_action_just_pressed("slide") and abs(player.velocity.x) > player.speed * 0.5:
			state_machine.transition_to("slide")
			return
	else:
		# Transition to idle when no input
		state_machine.transition_to("idle")
		return
	
	# Handle jump
	if Input.is_action_just_pressed("jump"):
		player.velocity.y = player.jump_velocity
		state_machine.transition_to("jump")
		return

	# Handle attack
	if Input.is_action_just_pressed("attack"):
		state_machine.transition_to("attack")
		return

	# Apply movement
	player.move_and_slide()
