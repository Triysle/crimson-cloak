extends EnemyState

var wander_time: float = 0
var wander_duration: float = 2.0
var direction: int = 0  # -1 for left, 1 for right

func enter():
	# Play walk animation
	enemy.animation_player.play("walk")
	
	# Reset wander time
	wander_time = 0
	
	# Pick a random direction
	direction = [-1, 1][randi() % 2]
	
	# Update sprite facing
	enemy.update_facing(direction)

func exit():
	# Reset the timer
	wander_time = 0

func physics_update(delta):
	# Apply gravity
	if not enemy.is_on_floor():
		enemy.velocity.y += enemy.gravity * delta
	
	# Move in the chosen direction
	var target_velocity = direction * enemy.movement_speed
	enemy.velocity.x = move_toward(enemy.velocity.x, target_velocity, enemy.acceleration * delta)
	
	# Increment timer
	wander_time += delta
	
	# Check if the player is within detection range
	if enemy.player_detected and enemy.target != null:
		state_machine.transition_to("chase")
		return
	
	# Check if we've wandered too far from spawn point
	var distance_from_spawn = enemy.global_position.distance_to(enemy.spawn_position)
	if distance_from_spawn > enemy.wander_range:
		# Turn around and head back
		direction = 1 if enemy.spawn_position.x > enemy.global_position.x else -1
		enemy.update_facing(direction)
	
	# Check for obstacles or edges
	if enemy.is_on_wall():
		# Turn around
		direction *= -1
		enemy.update_facing(direction)
	
	# After wander duration, transition to idle
	if wander_time >= wander_duration:
		state_machine.transition_to("idle")
		return
