extends State

# State tracking
enum DeathPhase {FALLING, LANDED, ANIMATING, COMPLETED}
var current_phase = DeathPhase.FALLING
var death_timer = 0.0
var post_animation_delay = 2.0  # Delay after death animation completes

func enter():
	# Initialize the death state
	if player.is_on_floor():
		# Already on floor, go straight to animation
		current_phase = DeathPhase.LANDED
		player.animation_player.play("die")
	else:
		# In air, keep falling animation
		current_phase = DeathPhase.FALLING
		player.animation_player.play("fall")
	
	# Disable player control
	player.can_control = false
	
	# Reset timer
	death_timer = 0.0
	
	# Connect to the animation_finished signal
	if not player.animation_player.animation_finished.is_connected(self._on_animation_finished):
		player.animation_player.animation_finished.connect(self._on_animation_finished)

func physics_update(delta):
	# Apply gravity if falling
	if current_phase == DeathPhase.FALLING:
		player.velocity.y += player.gravity * delta
		
		# Check if we've landed
		if player.is_on_floor():
			current_phase = DeathPhase.LANDED
			# Stop horizontal movement upon landing
			player.velocity.x = 0
			player.animation_player.play("die")
	
	# Timer for after animation is complete
	elif current_phase == DeathPhase.ANIMATING:
		death_timer += delta
		if death_timer >= post_animation_delay:
			current_phase = DeathPhase.COMPLETED
			# Signal that we're ready to respawn
			GameManager.respawn_player()
	
	# Move the player
	player.move_and_slide()

func _on_animation_finished(anim_name):
	if anim_name == "die" and current_phase == DeathPhase.LANDED:
		current_phase = DeathPhase.ANIMATING
		death_timer = 0.0

func exit():
	# Disconnect the signal if connected
	if player.animation_player.animation_finished.is_connected(self._on_animation_finished):
		player.animation_player.animation_finished.disconnect(self._on_animation_finished)
