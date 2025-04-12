extends EnemyState

var edge_detection_enabled = true  # Set to false to disable edge detection

func enter():
	# Play walk/run animation
	enemy.animation_player.play("walk")

func exit():
	pass

func physics_update(delta):
	# Make sure we have a valid target
	if enemy.target == null:
		state_machine.transition_to("idle")
		return
	
	# Check if player is still detected
	if not enemy.player_detected:
		state_machine.transition_to("idle")
		return
	
	# Apply gravity if not on floor
	if not enemy.is_on_floor():
		enemy.velocity.y += enemy.gravity * delta
	
	# Get direction to player
	var direction = sign(enemy.target.global_position.x - enemy.global_position.x)
	
	# Update sprite direction
	enemy.update_facing(direction)
	
	# Move towards player
	var target_velocity = direction * enemy.movement_speed
	enemy.velocity.x = move_toward(enemy.velocity.x, target_velocity, enemy.acceleration * delta)
	
	# Check if we're close enough to attack
	var distance_to_target = enemy.global_position.distance_to(enemy.target.global_position)
	if distance_to_target <= enemy.attack_range and enemy.can_attack:
		state_machine.transition_to("attack")
		return
	
	# Check if we've gone too far from spawn point
	var spawn_distance = enemy.global_position.distance_to(enemy.spawn_position)
	if spawn_distance > enemy.wander_range * 1.5:
		enemy.player_detected = false
		state_machine.transition_to("idle")
		return
