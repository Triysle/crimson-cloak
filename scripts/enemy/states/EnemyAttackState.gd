extends EnemyState

var attack_timer: float = 0
var attack_cooldown: float = 1.0
var attack_duration: float = 0.8  # How long the attack animation plays
var damage_dealt: bool = false
var can_attack_again: bool = true  # New variable to control attack looping
var current_animation: String = ""

func enter():
	# Choose between attack animations based on random factor
	if randf() < 0.7:  # 70% chance to use attackA
		current_animation = "attackA"
		enemy.animation_player.play("attackA")
	else:
		current_animation = "attackB"
		enemy.animation_player.play("attackB")
	
	damage_dealt = false
	can_attack_again = true
	
	# Stop movement
	enemy.velocity.x = 0
	
	# Connect to animation_finished signal
	if not enemy.animation_player.animation_finished.is_connected(_on_animation_finished):
		enemy.animation_player.animation_finished.connect(_on_animation_finished)

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
	
	# Disconnect from animation_finished signal to prevent memory leaks
	if enemy.animation_player.animation_finished.is_connected(_on_animation_finished):
		enemy.animation_player.animation_finished.disconnect(_on_animation_finished)

func physics_update(delta):
	# Make sure we have a valid target
	if enemy.target == null:
		return  # Don't end attack, wait for animation to finish
	
	# Apply gravity
	if not enemy.is_on_floor():
		enemy.velocity.y += enemy.gravity * delta
		
	# Face the player
	var direction = sign(enemy.target.global_position.x - enemy.global_position.x)
	if direction != 0:
		enemy.update_facing(direction)
	
	# Keep the enemy in place during attack
	enemy.velocity.x = move_toward(enemy.velocity.x, 0, enemy.friction * delta)

func _on_animation_finished(anim_name: String):
	# Only respond to our attack animations
	if anim_name == current_animation:
		# After attack animation completes, transition to chase
		if enemy.target and enemy.player_detected:
			state_machine.transition_to("chase")
		else:
			state_machine.transition_to("idle")
