extends EnemyState

func enter():
	# Play walk/run animation
	enemy.animation_player.play("walk")

func physics_update(delta):
	# Make sure we have a valid target
	if enemy.target == null:
		state_machine.transition_to("idle")
		return
	
	# Apply gravity if not on floor
	if not enemy.is_on_floor():
		enemy.velocity.y += enemy.gravity * delta
	
	# Get direction to player
	var direction = sign(enemy.target.global_position.x - enemy.global_position.x)
	
	# Update sprite direction
	if direction != 0:
		enemy.update_facing(direction)
	
	# Move towards player
	enemy.velocity.x = move_toward(enemy.velocity.x, direction * enemy.movement_speed, enemy.acceleration * delta)
	
	# Check if we're close enough to attack
	var distance = enemy.global_position.distance_to(enemy.target.global_position)
	if distance <= enemy.attack_range and enemy.can_attack:
		state_machine.transition_to("attack")
		return
	
	# Check if we've gone too far from spawn point
	var spawn_distance = enemy.global_position.distance_to(enemy.spawn_position)
	if spawn_distance > enemy.wander_range * 1.5:
		enemy.player_detected = false
		state_machine.transition_to("idle")
		return
		
	# Stop chasing if we hit a wall or edge
	if enemy.is_on_wall() or !enemy.is_on_floor():
		enemy.velocity.x = 0
