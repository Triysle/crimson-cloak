extends State

func enter():
	player.animation_player.play("run")

func physics_update(delta):
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
	else:
		# Transition to idle when no input
		state_machine.transition_to("idle")
		return
	
	# Handle jump
	if Input.is_action_just_pressed("jump"):
		player.velocity.y = player.jump_velocity
		state_machine.transition_to("jump")
		return
	
	# Apply movement
	player.move_and_slide()
