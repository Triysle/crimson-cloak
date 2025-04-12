extends EnemyState

var idle_timer: float = 0
var idle_duration: float = 3.0  # Time to stay idle before wandering again

func enter():
	# Play idle animation
	enemy.animation_player.play("idle")
	idle_timer = 0

func physics_update(delta):
	# Apply friction to slow down
	enemy.velocity.x = move_toward(enemy.velocity.x, 0, enemy.friction * delta)
	
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
