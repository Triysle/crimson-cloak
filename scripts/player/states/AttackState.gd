extends State

var attack_combo_window = 0.5  # Time window to input the next attack in combo
var attack_timer = 0.0  # Timer to track combo window
var current_attack = 1  # Track which attack in the combo we're on (1, 2, or 3)
var can_combo = false  # Whether player can continue combo
var combo_requested = false  # Flag to track if player has requested next combo attack
var combo_active = false  # Track if we're in the middle of a combo
var step_impulse = 100.0  # Impulse force for stepping forward
var step_applied = false  # Track if we've applied the step for current attack

func enter():
	# Check if we're in the air
	var in_air = not player.is_on_floor()	

	# Check if we're starting a new attack sequence or continuing a combo
	if player.state_machine.current_state.name != "Attack" || !combo_active:
		current_attack = 1
		combo_active = true
	elif in_air && current_attack >= 2:
		# Limit to only first two attacks in air
		current_attack = 2
	
	# Play the appropriate attack animation
	player.animation_player.play("attack" + str(current_attack))
	
	attack_timer = 0.0
	can_combo = false  # Initially can't combo until animation reaches combo window
	combo_requested = false
	step_applied = false  # Reset step flag for new attack

func exit():
	# When exiting the attack state completely, reset combo state
	combo_active = false

func update(delta):
	attack_timer += delta
	
	# Enable combo input after certain point in animation
	if attack_timer > 0.15 and not can_combo:
		can_combo = true
	
	# Check for next attack input during combo window
	if can_combo and Input.is_action_just_pressed("attack"):
		combo_requested = true

func physics_update(delta):
	# Apply gravity
	if not player.is_on_floor():
		player.velocity.y += player.gravity * delta
		
		# Get movement input (with reduced control in air)
		var direction = Input.get_axis("move_left", "move_right")
		if abs(direction) > 0.1:
			# Apply air control (reduced compared to normal movement)
			player.velocity.x = move_toward(player.velocity.x, direction * player.speed * 0.7, 
										  player.acceleration * delta * 0.5)
			
			# Update player facing direction
			if direction > 0:
				player.sprite.flip_h = false
			elif direction < 0:
				player.sprite.flip_h = true
	else:
		# Ground attack handling
		# Get movement input
		var direction = Input.get_axis("move_left", "move_right")
		
		# Apply step movement at specific point in the attack animation
		if not step_applied and attack_timer > 0.1 and attack_timer < 0.15:
			if abs(direction) > 0.1:
				# Apply step impulse in input direction
				player.velocity.x = direction * step_impulse
				
				# Update player facing direction
				if direction > 0:
					player.sprite.flip_h = false
				elif direction < 0:
					player.sprite.flip_h = true
					
				step_applied = true
		else:
			# Apply friction to slow down after the step
			player.velocity.x = move_toward(player.velocity.x, 0, player.friction * delta)
	
	# Check for jump input during attack (including double jump)
	if Input.is_action_just_pressed("jump"):
		if player.is_on_floor():
			player.velocity.y = player.jump_velocity
			state_machine.transition_to("jump")
			return
		elif player.can_double_jump:
			player.can_double_jump = false
			state_machine.transition_to("doublejump")
			return
	
	# Apply movement
	player.move_and_slide()

func next_combo():
	# This is called when the current attack animation is finished
	if combo_requested:
		current_attack = (current_attack % 3) + 1  # Cycle between 1, 2, 3
		enter()  # Restart the state with the next attack
		return true
	
	# If no combo requested, we're exiting the combo sequence
	combo_active = false
	return false
