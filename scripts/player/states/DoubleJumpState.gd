extends State

func enter():
	player.animation_player.play("jump")  # Reuse the jump animation for now
	player.spawn_dust_effect("jump")
	player.velocity.y = player.jump_velocity * 0.8  # Slightly weaker than first jump

func physics_update(delta):
	# Apply gravity
	player.velocity.y += player.gravity * delta
	
	# Transition to fall state when velocity becomes positive (going down)
	if player.velocity.y > 0:
		state_machine.transition_to("fall")
		return
	
	# Get the input direction
	var direction = Input.get_axis("move_left", "move_right")
	
	if direction != 0:
		# Apply acceleration (but maybe slightly reduced in air)
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
