extends State

var block_reduction = 0.9  # 90% damage reduction when blocking
var block_knockback_speed = 150.0  # Knockback speed when hit while crouching and blocking
var original_height: float = 0
var original_position: Vector2 = Vector2.ZERO
var crouch_height_reduction = 0.5  # 50% of original height

func enter():
	player.animation_player.play("crouchblock")
	
	# Store original collision shape properties
	var collision_shape = player.get_node("CollisionShape2D")
	original_height = collision_shape.shape.height
	original_position = collision_shape.position
	
	# Reduce collision shape height for crouching
	collision_shape.shape.height = original_height * crouch_height_reduction
	
	# Move the collision shape up to keep the feet at the same level
	var height_diff = original_height - collision_shape.shape.height
	collision_shape.position.y = original_position.y - height_diff / 2
	
	# Stop horizontal movement when crouching and blocking
	player.velocity.x = 0

func exit():
	# Restore original collision shape properties
	var collision_shape = player.get_node("CollisionShape2D")
	collision_shape.shape.height = original_height
	collision_shape.position = original_position

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
		player.hud.update_health(player.health, max(0, player.health))
	
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
	# Create a shape cast to check above the player
	var space_state = player.get_world_2d().direct_space_state
	var query = PhysicsShapeQueryParameters2D.new()
	
	# Copy the player's collision shape
	var collision_shape = player.get_node("CollisionShape2D")
	query.set_shape(collision_shape.shape)
	
	# Position the shape at the standing height
	var standing_position = player.global_position
	query.transform = Transform2D(0, standing_position)
	
	# Only collide with the world layer
	query.collision_mask = 1  # Layer 1 is typically world
	
	# Exclude the player itself
	query.exclude = [player]
	
	# Check for collisions
	var result = space_state.intersect_shape(query)
	
	# If we have any collisions, we can't stand up
	return result.size() > 0
