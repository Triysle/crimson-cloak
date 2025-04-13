extends State

var knockback_force = 300.0
var hurt_duration = 0.4  # Match the animation duration
var hurt_timer = 0.0

func enter():
	player.animation_player.play("hurt")
	hurt_timer = 0.0
	
	# Apply knockback based on the stored hit direction
	player.velocity.x = player.hit_direction * knockback_force
	player.velocity.y = -160.0  # Small upward bounce
	
	# Disable control during hurt state
	player.can_control = false

func exit():
	# Re-enable control
	player.can_control = true

func physics_update(delta):
	# Update timer
	hurt_timer += delta
	
	# Apply gravity
	player.velocity.y += player.gravity * delta
	
	# Gradually reduce horizontal velocity (air resistance/friction)
	player.velocity.x = move_toward(player.velocity.x, 0, player.friction * delta)
	
	# Move the player
	player.move_and_slide()
	
	# Transition back to appropriate state after hurt duration
	if hurt_timer >= hurt_duration:
		if player.is_on_floor():
			state_machine.transition_to("idle")
		else:
			state_machine.transition_to("fall")
