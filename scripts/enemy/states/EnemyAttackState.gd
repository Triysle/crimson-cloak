extends EnemyState

var attack_timer: float = 0
var attack_cooldown: float = 1.0
var attack_duration: float = 0.5  # How long the attack animation plays
var damage_dealt: bool = false

func enter():
	# Play attack animation
	if randf() < 0.7:  # 70% chance to use attackA
		enemy.animation_player.play("attackA")
	else:
		enemy.animation_player.play("attackB")
	
	attack_timer = 0
	damage_dealt = false
	
	# Stop movement
	enemy.velocity.x = 0

func update(delta):
	attack_timer += delta
	
	# Apply damage at a specific point in the animation
	if attack_timer > 0.2 and attack_timer < 0.3 and not damage_dealt:
		apply_damage()
		damage_dealt = true

func physics_update(delta):
	# Make sure we have a valid target
	if enemy.target == null:
		end_attack()
		return
	
	# Apply gravity
	if not enemy.is_on_floor():
		enemy.velocity.y += enemy.gravity * delta
		
	# Face the player
	var direction = sign(enemy.target.global_position.x - enemy.global_position.x)
	if direction != 0:
		enemy.sprite.flip_h = (direction < 0)
	
	# End attack after duration
	if attack_timer >= attack_duration:
		end_attack()

func exit():
	# Reset attack cooldown
	enemy.can_attack = false
	
	# Start a timer to re-enable attacks
	var timer = get_tree().create_timer(attack_cooldown)
	await timer.timeout
	enemy.can_attack = true

func apply_damage():
	# Check if player is still in range
	if enemy.target == null:
		return
		
	var distance = enemy.global_position.distance_to(enemy.target.global_position)
	if distance <= enemy.attack_range:
		# Enable attack hitbox
		if enemy.attack_box.has_method("apply_damage"):
			enemy.attack_box.apply_damage(enemy.target, enemy.damage)
		# Alternative way - directly call player's damage function
		elif enemy.target.has_method("take_damage"):
			enemy.target.take_damage(enemy.damage)

func end_attack():
	if enemy.target and enemy.player_detected:
		var distance = enemy.global_position.distance_to(enemy.target.global_position)
		if distance <= enemy.attack_range and enemy.can_attack:
			# Immediately attack again if in range
			state_machine.transition_to("attack")
		else:
			# Chase if out of range
			state_machine.transition_to("chase")
	else:
		# Return to idle if player lost
		state_machine.transition_to("idle")
