extends State

var knockback_force = 100.0
var hurt_duration = 0.5
var hurt_timer = 0.0
var hit_direction = 0.0

func enter(params := {}):
	player.animation_player.play("hurt")
	hurt_timer = 0.0
	
	# Get the hit direction from parameters if provided
	if params.has("direction"):
		hit_direction = params.get("direction")
	else:
		# Default: knockback opposite to player's facing direction
		hit_direction = -1.0 if player.sprite.flip_h else 1.0
	
	# Apply knockback force
	player.velocity.x = -hit_direction * knockback_force
	player.velocity.y = -50.0  # Small upward boost
	
	# Briefly disable collision with enemies to prevent multiple hits
	# You might need to set up collision layers for this
	# player.set_collision_mask_value(2, false)  # Layer 2 for enemies

func exit():
	# Re-enable collision with enemies
	# player.set_collision_mask_value(2, true)
	pass

func physics_update(delta):
	# Update timer
	hurt_timer += delta
	
	# Apply gravity
	player.velocity.y += player.gravity * delta
	
	# Gradually reduce knockback
	player.velocity.x = move_toward(player.velocity.x, 0, player.friction * delta)
	
	# Move the player
	player.move_and_slide()
	
	# Transition back to appropriate state after hurt duration
	if hurt_timer >= hurt_duration:
		if player.is_on_floor():
			state_machine.transition_to("idle")
		else:
			state_machine.transition_to("fall")
