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
	
	enemy.debug_print("WanderState.enter() with direction: " + str(direction) + ", velocity: " + str(enemy.velocity))
	
	# Update sprite facing
	enemy.update_facing(direction)

func exit():
	# Reset the timer
	wander_time = 0
	enemy.debug_print("WanderState.exit() with velocity: " + str(enemy.velocity))

func physics_update(delta):
	# Apply gravity
	if not enemy.is_on_floor():
		enemy.velocity.y += enemy.gravity * delta
	
	# Move in the chosen direction
	var old_velocity_x = enemy.velocity.x
	var target_velocity = direction * enemy.movement_speed
	
	enemy.debug_print("WanderState attempting to move with speed: " + str(enemy.movement_speed) + 
					", direction: " + str(direction) + 
					", target velocity: " + str(target_velocity))
	
	enemy.velocity.x = move_toward(enemy.velocity.x, target_velocity, enemy.acceleration * delta)
	
	if abs(old_velocity_x - enemy.velocity.x) > 0.1:
		enemy.debug_print("WanderState updated velocity.x: " + str(old_velocity_x) + " -> " + str(enemy.velocity.x))
	
	# Increment timer
	wander_time += delta
	
	# Debug movement info
	if enemy.is_on_wall():
		enemy.debug_print("WanderState detected wall collision")
	
	if not enemy.is_on_floor():
		enemy.debug_print("WanderState detected not on floor")
	
	# Check if the player is within detection range
	if enemy.player_detected and enemy.target != null:
		state_machine.transition_to("chase")
		return
	
	# Check if we've wandered too far from spawn point
	var distance_from_spawn = enemy.global_position.distance_to(enemy.spawn_position)
	if distance_from_spawn > enemy.wander_range:
		# Turn around and head back
		var new_direction = 1 if enemy.spawn_position.x > enemy.global_position.x else -1
		
		if new_direction != direction:
			enemy.debug_print("WanderState changing direction because too far from spawn: " + 
						   str(direction) + " -> " + str(new_direction) + 
						   " (distance: " + str(distance_from_spawn) + ")")
			
			direction = new_direction
			enemy.update_facing(direction)
	
	# Check for obstacles or edges
	if enemy.is_on_wall():
		# Turn around
		enemy.debug_print("WanderState hit wall, changing direction: " + str(direction) + " -> " + str(-direction))
		
		direction *= -1
		enemy.update_facing(direction)
	
	# Debug if velocity doesn't match expected direction
	if sign(enemy.velocity.x) != 0 and sign(enemy.velocity.x) != direction:
		enemy.debug_print("WARNING: Velocity direction (" + str(sign(enemy.velocity.x)) + 
					   ") doesn't match intended direction (" + str(direction) + ")")
	
	# After wander duration, transition to idle
	if wander_time >= wander_duration:
		state_machine.transition_to("idle")
		return
