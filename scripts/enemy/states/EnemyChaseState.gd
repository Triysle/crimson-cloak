extends EnemyState

var edge_detection_enabled = true  # Set to false to disable edge detection

func enter():
	# Play walk/run animation
	enemy.animation_player.play("walk")
	enemy.debug_print("ChaseState.enter() with velocity: " + str(enemy.velocity))

func exit():
	enemy.debug_print("ChaseState.exit() with velocity: " + str(enemy.velocity))

func physics_update(delta):
	# Make sure we have a valid target
	if enemy.target == null:
		enemy.debug_print("ChaseState: No target found, transitioning to idle")
		state_machine.transition_to("idle")
		return
	
	# Check if player is still detected
	if not enemy.player_detected:
		enemy.debug_print("ChaseState: Player no longer detected")
		# This would normally create a timer, but for debugging we'll just transition immediately
		state_machine.transition_to("idle")
		return
	
	# Apply gravity if not on floor
	if not enemy.is_on_floor():
		enemy.velocity.y += enemy.gravity * delta
	
	# Get direction to player
	var direction = sign(enemy.target.global_position.x - enemy.global_position.x)
	
	# Debug target info
	var distance_to_target = enemy.global_position.distance_to(enemy.target.global_position)
	enemy.debug_print("ChaseState: Target at distance " + str(distance_to_target) + 
				   ", direction " + str(direction))
	
	# Update sprite direction
	enemy.update_facing(direction)
	
	# Move towards player
	var old_velocity_x = enemy.velocity.x
	var target_velocity = direction * enemy.movement_speed
	
	enemy.debug_print("ChaseState attempting to move with speed: " + str(enemy.movement_speed) + 
					", direction: " + str(direction) + 
					", target velocity: " + str(target_velocity))
	
	enemy.velocity.x = move_toward(enemy.velocity.x, target_velocity, enemy.acceleration * delta)
	
	if abs(old_velocity_x - enemy.velocity.x) > 0.1:
		enemy.debug_print("ChaseState updated velocity.x: " + str(old_velocity_x) + " -> " + str(enemy.velocity.x))
	
	# Check if we're close enough to attack
	if distance_to_target <= enemy.attack_range and enemy.can_attack:
		enemy.debug_print("ChaseState: In attack range, transitioning to attack")
		state_machine.transition_to("attack")
		return
	
	# Check if we've gone too far from spawn point
	var spawn_distance = enemy.global_position.distance_to(enemy.spawn_position)
	if spawn_distance > enemy.wander_range * 1.5:
		enemy.debug_print("ChaseState: Too far from spawn (" + str(spawn_distance) + "), returning to idle")
		enemy.player_detected = false
		state_machine.transition_to("idle")
		return
	
	# Debug movement issues
	if enemy.is_on_wall():
		enemy.debug_print("ChaseState detected wall collision")
	
	if not enemy.is_on_floor():
		enemy.debug_print("ChaseState detected not on floor")
		
	# Avoid falling off edges without platform
	if edge_detection_enabled and enemy.is_on_floor():
		var next_pos = enemy.global_position + Vector2(direction * 20, 0)
		var space_state = enemy.get_world_2d().direct_space_state
		var query = PhysicsRayQueryParameters2D.create(next_pos, next_pos + Vector2(0, 50))
		query.collision_mask = 1  # Adjust to your collision layer
		var result = space_state.intersect_ray(query)
		
		if result.is_empty():
			enemy.debug_print("ChaseState: Edge detected, stopping horizontal movement")
			enemy.velocity.x = 0
	
	# Debug if velocity doesn't match expected direction
	if sign(enemy.velocity.x) != 0 and sign(enemy.velocity.x) != direction:
		enemy.debug_print("WARNING: Velocity direction (" + str(sign(enemy.velocity.x)) + 
					   ") doesn't match intended direction (" + str(direction) + ")")
