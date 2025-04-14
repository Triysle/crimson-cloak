extends State

var spawn_height = 48
var fade_duration = 0.5
var spawn_duration = 0.5
var timer = 0.0
var spawn_position = Vector2.ZERO

func enter():
	# Save original position for reference
	spawn_position = player.global_position
	
	# Move player up by spawn_height
	player.global_position.y -= spawn_height
	
	# Set player as invisible initially
	player.modulate.a = 0.0
	
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
		player.modulate.a = timer / fade_duration
	
	# After spawn_duration, transition to fall state
	if timer >= spawn_duration:
		# Re-enable player control
		player.can_control = true
		
		# Transition to fall state to start normal gameplay
		state_machine.transition_to("fall")
		return
	
	# Keep player in place during the spawn animation
	player.velocity = Vector2.ZERO
