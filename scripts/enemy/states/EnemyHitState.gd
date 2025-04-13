extends EnemyState

var hit_duration: float = 0.3  # Duration of hit state
var hit_timer: float = 0.0     # Track elapsed time
var hit_knockback: float = 100.0  # Knockback force

func enter():
	# Play hit animation
	enemy.animation_player.play("hit")
	hit_timer = 0.0
	
	# Apply knockback based on player position
	if enemy.target != null:
		var direction = sign(enemy.global_position.x - enemy.target.global_position.x)
		if direction == 0:
			direction = 1  # Default direction if somehow aligned
		
		# Apply knockback velocity
		enemy.velocity.x = direction * hit_knockback
		enemy.velocity.y = -50.0  # Small upward force
	
	# Face toward the player
	if enemy.target != null:
		var direction = sign(enemy.target.global_position.x - enemy.global_position.x)
		enemy.update_facing(direction)

func exit():
	# Decelerate to zero
	enemy.velocity.x = 0

func physics_update(delta):
	# Update timer
	hit_timer += delta
	
	# Apply gravity
	if not enemy.is_on_floor():
		enemy.velocity.y += enemy.gravity * delta
	
	# Apply movement
	enemy.move_and_slide()
	
	# Gradually reduce knockback
	enemy.velocity.x = move_toward(enemy.velocity.x, 0, enemy.friction * delta)
	
	# Transition after hit duration completes
	if hit_timer >= hit_duration:
		if enemy.player_detected and enemy.target != null:
			state_machine.transition_to("chase")
		else:
			state_machine.transition_to("idle")
