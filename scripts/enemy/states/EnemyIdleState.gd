extends EnemyState

var idle_timer: float = 0.0
var idle_duration: float = 3.0  # Time to stay idle before wandering again

func enter():
	# Play idle animation
	enemy.animation_player.play("idle")
	idle_timer = 0
	
	# Debug velocity at idle enter
	enemy.debug_print("IdleState.enter() with velocity: " + str(enemy.velocity))
	
	# Stop horizontal movement - BUT LOG IT FOR DEBUGGING
	var old_velocity_x = enemy.velocity.x
	enemy.velocity.x = 0
	
	if old_velocity_x != 0:
		enemy.debug_print("IdleState.enter() zeroed velocity.x from: " + str(old_velocity_x))

func exit():
	# Reset the timer
	idle_timer = 0
	enemy.debug_print("IdleState.exit() with velocity: " + str(enemy.velocity))

func physics_update(delta):
	# Apply gravity
	if not enemy.is_on_floor():
		enemy.velocity.y += enemy.gravity * delta
		state_machine.transition_to("fall")
		return
	
	# Apply friction to slow down
	var old_velocity_x = enemy.velocity.x
	enemy.velocity.x = move_toward(enemy.velocity.x, 0, enemy.friction * delta)
	
	# Force movement to unstick enemy if they're "stuck"
	if enemy.is_on_floor() and abs(enemy.velocity.x) < 0.1 and enemy.idle_timer > 1.0:
		# Apply a small horizontal push
		enemy.velocity.x = (10.0 * enemy.facing_direction)
		enemy.debug_print("Applying recovery push: " + str(enemy.velocity.x))
	
	# Move the enemy
	enemy.move_and_slide()
	
	# Increment timer
	idle_timer += delta
	
	# Check if the player is within detection range
	if enemy.player_detected and enemy.target != null:
		state_machine.transition_to("chase")
		return
	
	# After idle duration, transition to wander
	if idle_timer >= idle_duration:
		state_machine.transition_to("wander")
		return
