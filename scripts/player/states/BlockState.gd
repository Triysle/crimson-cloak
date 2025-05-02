extends State

var block_reduction = 0.9  # 90% damage reduction when blocking
var block_knockback_speed = 200.0  # Knockback speed when hit while blocking
var can_block_in_air = false  # Whether player can block while in air

func enter():
	player.animation_player.play("block")
	# Stop horizontal movement when starting to block
	player.velocity.x = 0
	
func exit():
	# Reset any block-specific properties if needed
	pass
	
func update(delta):
	# Handle any continuous effects or animations here
	pass

func physics_update(delta):
	# Skip input processing if player can't be controlled
	if not player.can_control:
		return
		
	# Apply gravity if in air
	if not player.is_on_floor():
		player.velocity.y += player.gravity * delta
	
	# Keep player in place (no horizontal movement while blocking)
	player.velocity.x = 0
	
	# Check if block button is released
	if not Input.is_action_pressed("block"):
		# Transition back to appropriate state
		if player.is_on_floor():
			if Input.is_action_pressed("move_down"):
				# If still holding down, go to crouch
				state_machine.transition_to("crouch")
			else:
				state_machine.transition_to("idle")
		else:
			state_machine.transition_to("fall")
		return
	
	# Check if player wants to crouch while blocking
	if player.is_on_floor() and Input.is_action_just_pressed("move_down"):
		state_machine.transition_to("crouchblock")
		return
	
	# Jump while blocking (if on floor)
	if player.is_on_floor() and Input.is_action_just_pressed("jump"):
		player.velocity.y = player.jump_velocity
		state_machine.transition_to("jump")
		return
		
	# Attack cancels block
	if Input.is_action_just_pressed("attack"):
		state_machine.transition_to("attack")
		return
	
	# Apply movement
	player.move_and_slide()

# Called when player takes damage while blocking
func take_block_damage(amount: int, attacker_position: Vector2):
	# Calculate reduced damage
	var reduced_damage = int(amount * (1 - block_reduction))
	
	# Apply the reduced damage
	player.health -= reduced_damage
	
	# Update the HUD
	if player.hud:
		player.hud.update_health(player.health, max(0, player.health))
	
	# Calculate knockback direction
	var knockback_dir = sign(player.global_position.x - attacker_position.x)
	if knockback_dir == 0:
		knockback_dir = 1.0  # Default direction if directly above/below
	
	# Apply knockback
	player.velocity.x = knockback_dir * block_knockback_speed
	
	# Play block knockback animation
	player.animation_player.play("blockknockback")
	
	# Check if player has died
	if player.health <= 0:
		player.die()
