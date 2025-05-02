extends Area2D

signal ledge_detected(position)
signal ledge_exited

var is_near_ledge = false
var current_ledge_position = Vector2.ZERO
var cooldown_timer = 0.0
var cooldown_duration = 0.5  # Time before grabbing the same ledge again

func _ready():
	# Make sure to connect the signals
	connect("body_entered", _on_body_entered)
	connect("body_exited", _on_body_exited)

func _process(delta):
	# Update cooldown timer
	if cooldown_timer > 0:
		cooldown_timer -= delta

func _on_body_entered(body):
	# Only detect ledges if we're not in cooldown
	if cooldown_timer <= 0 and body.is_in_group("ledge"):
		# Calculate the ledge position based on the colliding body
		var ledge_pos = calculate_ledge_position(body)
		
		# Store the ledge position
		current_ledge_position = ledge_pos
		is_near_ledge = true
		
		# Emit signal that a ledge was detected
		emit_signal("ledge_detected", current_ledge_position)

func _on_body_exited(body):
	if body.is_in_group("ledge") and is_near_ledge:
		is_near_ledge = false
		emit_signal("ledge_exited")
		
		# Start cooldown timer
		cooldown_timer = cooldown_duration

# Calculate the best position for the player to grab this ledge
func calculate_ledge_position(ledge_body):
	var ledge_position = Vector2.ZERO
	
	# Get the ledge's collision shape
	var ledge_collision
	for child in ledge_body.get_children():
		if child is CollisionShape2D or child is CollisionPolygon2D:
			ledge_collision = child
			break
	
	if ledge_collision:
		# If it's a rectangle shape, we grab the top edge
		if ledge_collision is CollisionShape2D and ledge_collision.shape is RectangleShape2D:
			var rect_shape = ledge_collision.shape
			var top_y = ledge_body.global_position.y - rect_shape.extents.y
			
			# Decide which side of the ledge to grab based on player position
			var player = get_parent()
			var side_offset = 8  # Offset from the edge
			
			if player.global_position.x < ledge_body.global_position.x:
				# Grab left side
				ledge_position = Vector2(ledge_body.global_position.x - rect_shape.extents.x + side_offset, top_y)
			else:
				# Grab right side
				ledge_position = Vector2(ledge_body.global_position.x + rect_shape.extents.x - side_offset, top_y)
		else:
			# For other shapes, just use the body's position as an approximation
			ledge_position = ledge_body.global_position
	else:
		# No collision shape found, use the body's position
		ledge_position = ledge_body.global_position
	
	return ledge_position

# Call this to manually reset the ledge detection after letting go
func reset_detection():
	is_near_ledge = false
	cooldown_timer = cooldown_duration
