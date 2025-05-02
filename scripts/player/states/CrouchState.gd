extends State

# Original collision shape properties to restore when exiting crouch
var original_height: float = 0
var original_position: Vector2 = Vector2.ZERO
var original_radius: float = 0

# Reduced collision height while crouching
var crouch_height_reduction = 0.5  # 50% of original height

func enter():
	player.animation_player.play("crouch")
	
	# Store original collision shape properties
	var collision_shape = player.get_node("CollisionShape2D")
	original_height = collision_shape.shape.height
	original_position = collision_shape.position
	
	# Store original radius if using a capsule shape
	if collision_shape.shape is CapsuleShape2D:
		original_radius = collision_shape.shape.radius
	
	# Reduce collision shape height for crouching
	collision_shape.shape.height = original_height * crouch_height_reduction
	
	# Important fix: Don't move the position.y - keep the feet at the same level
	# by leaving the bottom of the collision shape in place
	# This shrinks from the top down instead of from the bottom up
	
	# Stop horizontal movement when crouching
	player.velocity.x = 0

func exit():
	# Restore original collision shape properties
	var collision_shape = player.get_node("CollisionShape2D")
	collision_shape.shape.height = original_height
	collision_shape.position = original_position
	
	# Restore original radius if using a capsule shape
	if collision_shape.shape is CapsuleShape2D and original_radius > 0:
		collision_shape.shape.radius = original_radius

func physics_update(delta):
	# Skip input processing if player can't be controlled
	if not player.can_control:
		return
		
	# Apply gravity
	if not player.is_on_floor():
		player.velocity.y += player.gravity * delta
	
	# Keep player in place (no horizontal movement while crouching)
	player.velocity.x = 0
	
	# Check if down is released to stand up
	if not Input.is_action_pressed("move_down"):
		# Check if we can stand up (not blocked above) if on floor
		if not player.is_on_floor() or not is_blocked_above():
			if Input.is_action_pressed("block"):
				state_machine.transition_to("block")
			else:
				if player.is_on_floor():
					state_machine.transition_to("idle")
				else:
					state_machine.transition_to("fall")
		return
	
	# Check for block input while crouching
	if Input.is_action_just_pressed("block"):
		state_machine.transition_to("crouchblock")
		return
	
	# Check for fall-through platform
	if Input.is_action_just_pressed("jump"):
		if player.is_on_floor():
			player.fall_through_platforms()
		state_machine.transition_to("fall")
		return
		
	# Apply movement
	player.move_and_slide()

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
