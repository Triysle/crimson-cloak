extends State

var slide_timer = 0
var slide_duration = 0.5  # Duration of slide in seconds
var slide_speed_multiplier = 1.5  # Speed boost when starting the slide
var slide_deceleration = 0.7  # How quickly the slide slows down (lower = longer slide)

func enter():
	player.animation_player.play("slide")
	slide_timer = 0
	
	# Store original collision shape size for later restoration
	var collision_shape = player.get_node("NormalCollider")
	player.original_height = collision_shape.shape.height
	player.original_position = collision_shape.position
	player.original_radius = collision_shape.shape.radius
	
	# Reduce collision shape height and radius for sliding
	collision_shape.shape.height = 8.0
	collision_shape.shape.radius = 4.0  # Also adjust radius for a smaller collision overall
	# Move the collision shape down to maintain floor contact
	collision_shape.position.y = -4.0  # Adjusted to keep bottom of collision at the same level
	
	# Get the direction based on current velocity rather than sprite direction
	var direction = sign(player.velocity.x)
	if direction == 0:  # If somehow velocity is 0, use sprite direction
		direction = -1.0 if player.sprite.flip_h else 1.0
	
	# Boost initial slide speed based on current momentum
	var current_speed = abs(player.velocity.x)
	player.velocity.x = direction * max(current_speed, player.speed) * slide_speed_multiplier
	
	# Force floor contact check in the next frame
	player.velocity.y = 1.0  # Tiny downward velocity to stick to floor

func exit():
	# Restore original collision shape size and position
	var collision_shape = player.get_node("NormalCollider")
	collision_shape.shape.height = player.original_height
	collision_shape.shape.radius = player.original_radius
	collision_shape.position = player.original_position

func physics_update(delta):
	# Skip input processing if player can't be controlled
	if not player.can_control:
		return
		
	# Increment timer
	slide_timer += delta
	
	# Apply gravity
	if not player.is_on_floor():
		player.velocity.y += player.gravity * delta
		state_machine.transition_to("fall")
		return
	
	# Gradually slow down the slide
	player.velocity.x = move_toward(player.velocity.x, 0, player.friction * slide_deceleration * delta)
	
	# Move the player
	player.move_and_slide()
	
	# End slide if timer expired, player stops, or player tries to change direction
	if slide_timer >= slide_duration or abs(player.velocity.x) < player.speed * 0.1 or player.is_on_wall():
		if abs(Input.get_axis("move_left", "move_right")) > 0.1:
			state_machine.transition_to("run")
		else:
			state_machine.transition_to("idle")
		return
	
	# Allow canceling slide with jump
	if Input.is_action_just_pressed("jump"):
		player.velocity.y = player.jump_velocity
		state_machine.transition_to("jump")
		return
