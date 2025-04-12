extends EnemyState

var attack_timer: float = 0
var attack_cooldown: float = 1.0
var attack_duration: float = 0.8  # How long the attack animation plays
var damage_dealt: bool = false
var can_attack_again: bool = true  # New variable to control attack looping

func enter():
	# Choose between attack animations based on random factor
	if randf() < 0.7:  # 70% chance to use attackA
		enemy.animation_player.play("attackA")
	else:
		enemy.animation_player.play("attackB")
	
	attack_timer = 0
	damage_dealt = false
	can_attack_again = true
	
	# Stop movement
	enemy.velocity.x = 0

func exit():
	# Reset attack cooldown
	enemy.can_attack = false
	can_attack_again = false
	
	# Explicitly disable the attack box collision shape
	if enemy.attack_box and enemy.attack_box.has_node("CollisionShape2D"):
		enemy.attack_box.get_node("CollisionShape2D").disabled = true
	
	# Start a timer to re-enable attacks
	var timer = get_tree().create_timer(attack_cooldown)
	timer.timeout.connect(func(): enemy.can_attack = true)

func update(delta):
	attack_timer += delta
	
	# Wait for animation to complete
	if attack_timer >= attack_duration:
		end_attack()

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
		enemy.update_facing(direction)
	
	# Keep the enemy in place during attack
	enemy.velocity.x = move_toward(enemy.velocity.x, 0, enemy.friction * delta)

func end_attack():
	# After one attack, always transition to chase instead of attacking again
	# This prevents getting stuck in an attack loop
	if enemy.target and enemy.player_detected:
		state_machine.transition_to("chase")
	else:
		state_machine.transition_to("idle")
