extends State

var spawn_height = 48
var fade_duration = 0.5
var spawn_duration = 0.5
var timer = 0.0
var spawn_position = Vector2.ZERO
var camera_smoothing_enabled = false

func enter():
	# Save original position for reference
	spawn_position = player.global_position
	
	# Move player up by spawn_height
	player.global_position.y -= spawn_height
	
	# Temporary disable camera smoothing and force position
	var camera = player.get_node("Camera2D")
	if camera:
		# Store current smoothing state
		camera_smoothing_enabled = camera.position_smoothing_enabled
		# Disable smoothing
		camera.position_smoothing_enabled = false
		# Force camera update
		camera.reset_smoothing()
	
	# Set player as invisible initially through the shader
	if player.sprite.material is ShaderMaterial:
		print("Using shader material for fade")
		player.sprite.material.set_shader_parameter("alpha_override", 0.0)
	else:
		# Fallback to modulate if no shader
		print("Using modulate for fade (fallback)")
		player.modulate = Color(1, 1, 1, 0)
	
	# Disable player control
	player.can_control = false
	
	# Play fall animation
	player.animation_player.play("fall")
	
	# Reset timer
	timer = 0.0

func physics_update(delta):
	timer += delta
	
	# Handle fading in
	if timer <= fade_duration:
		# Gradually increase alpha value
		var alpha = timer / fade_duration
		
		if player.sprite.material is ShaderMaterial:
			player.sprite.material.set_shader_parameter("alpha_override", alpha)
		else:
			player.modulate = Color(1, 1, 1, alpha)
	
	# After spawn_duration, transition to fall state
	if timer >= spawn_duration:
		# Re-enable player control
		player.can_control = true
		
		# Make sure player is fully visible
		if player.sprite.material is ShaderMaterial:
			player.sprite.material.set_shader_parameter("alpha_override", 1.0)
		else:
			player.modulate = Color(1, 1, 1, 1)
		
		# Re-enable camera smoothing
		var camera = player.get_node("Camera2D")
		if camera:
			camera.position_smoothing_enabled = camera_smoothing_enabled
		
		# Transition to fall state to start normal gameplay
		state_machine.transition_to("fall")
		return
	
	# Keep player in place during the spawn animation
	player.velocity = Vector2.ZERO
