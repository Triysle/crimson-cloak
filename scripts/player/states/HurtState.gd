extends State

var knockback_force = 500.0
var hurt_duration = 0.4  # Match the animation duration
var hurt_timer = 0.0
var pulse_active = false

func enter():
	player.animation_player.play("hurt")
	hurt_timer = 0.0
	
	# Apply knockback based on the stored hit direction
	player.velocity.x = player.hit_direction * knockback_force
	player.velocity.y = -160.0  # Small upward bounce
	
	# Disable control during hurt state
	player.can_control = false
	
	# Start pulsing effect
	if player.sprite.material is ShaderMaterial:
		player.sprite.material.set_shader_parameter("hurt_effect", 1.0)
		player.sprite.material.set_shader_parameter("pulse_time", 0.0)
		pulse_active = true

func exit():
	# Re-enable control
	player.can_control = true
	
	# Ensure hurt effect is reset
	if player.sprite.material is ShaderMaterial:
		player.sprite.material.set_shader_parameter("hurt_effect", 0.0)
		pulse_active = false

func update(delta):
	# Animate the pulse time parameter
	if pulse_active and player.sprite.material is ShaderMaterial:
		var current_time = player.sprite.material.get_shader_parameter("pulse_time")
		player.sprite.material.set_shader_parameter("pulse_time", current_time + delta * 5.0)

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
