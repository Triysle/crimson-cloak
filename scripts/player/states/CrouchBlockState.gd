extends State

var block_reduction = 0.9  # 90% damage reduction when blocking
var block_knockback_speed = 150.0  # Knockback speed when hit while crouching and blocking

func enter():
	player.animation_player.play("crouchblock")
	
	# Switch collision shapes
	player.get_node("NormalCollider").disabled = true
	player.get_node("CrouchCollider").disabled = false
	
	# Stop horizontal movement when crouching and blocking
	player.velocity.x = 0

func exit():
	# Switch back to normal collision shape
	player.get_node("NormalCollider").disabled = false
	player.get_node("CrouchCollider").disabled = true

func physics_update(delta):
	# Skip input processing if player can't be controlled
	if not player.can_control:
		return
		
	# Apply gravity if needed
	if not player.is_on_floor():
		player.velocity.y += player.gravity * delta
		state_machine.transition_to("fall")
		return
	
	# Keep player in place (no horizontal movement while crouching and blocking)
	player.velocity.x = 0
	
	# Check for directional input to change facing direction while blocking
	var direction = Input.get_axis("move_left", "move_right")
	if direction != 0:
		# Update player facing direction without moving
		if direction > 0:
			player.sprite.flip_h = false
		elif direction < 0:
			player.sprite.flip_h = true
	
	# Check if block is released
	if not Input.is_action_pressed("block"):
		state_machine.transition_to("crouch")
		return
	
	# Check if down is released while still blocking
	if not Input.is_action_pressed("move_down"):
		# Check if we can stand up (not blocked above)
		if not is_blocked_above():
			state_machine.transition_to("block")
		return
		
	# Apply movement
	player.move_and_slide()

# Called when player takes damage while crouch-blocking
func take_block_damage(amount: int, attacker_position: Vector2):
	# Calculate reduced damage
	var reduced_damage = int(amount * (1 - block_reduction))
	
	# Apply the reduced damage
	player.health -= reduced_damage
	
	# Update the HUD
	if player.hud:
		player.hud.update_health(player.health, player.max_health)
	
	# Calculate knockback direction
	var knockback_dir = sign(player.global_position.x - attacker_position.x)
	if knockback_dir == 0:
		knockback_dir = 1.0
	
	# Apply reduced knockback (less than standing block)
	player.velocity.x = knockback_dir * block_knockback_speed
	
	# Play block knockback animation
	player.animation_player.play("crouchblockknockback")
	
	# Check if player has died
	if player.health <= 0:
		player.die()

# Function to check if there's enough space to stand up
func is_blocked_above() -> bool:
	# Check if normal collider would intersect with something if enabled
	var normal_collider = player.get_node("NormalCollider")
	
	# Current position and rotation of the player
	var global_transform = player.global_transform
	
	# Create a direct space state query
	var space_state = player.get_world_2d().direct_space_state
	var query = PhysicsShapeQueryParameters2D.new()
	
	# Use the normal collider's shape
	query.set_shape(normal_collider.shape)
	query.transform = global_transform * normal_collider.transform
	
	# Only collide with the world layer
	query.collision_mask = 1  # Assuming world is on layer 1
	
	# Exclude the player itself
	query.exclude = [player]
	
	# Check for collisions
	var result = space_state.intersect_shape(query)
	
	# If we have any collisions, we can't stand up
	return result.size() > 0
