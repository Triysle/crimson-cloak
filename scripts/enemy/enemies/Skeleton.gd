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

func take_damage(amount: int):
	health -= amount
	
	if health <= 0:
		die()
	else:
		# Transition to hit state instead of just playing the animation
		state_machine.transition_to("hit")

# Override the drop_loot function
func drop_loot():
	# Here we'd spawn some coins or other loot
	print("Skeleton dropped loot!")
	# We'll implement actual loot spawning later
