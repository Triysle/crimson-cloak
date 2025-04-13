extends Enemy
class_name Skeleton

func _ready():
	# Call the parent _ready function
	super()
	
	# Set skeleton-specific properties
	max_health = 80
	health = 80
	damage = 15
	movement_speed = 70.0
	
	# Add to the "enemies" group if it doesn't exist already
	if not is_in_group("enemies"):
		add_to_group("enemies")

# Override the drop_loot function
func drop_loot():
	# Here we'd spawn some coins or other loot
	print("Skeleton dropped loot!")
	# We'll implement actual loot spawning later
