extends CharacterBody2D

# Player movement variables
@export var speed: float = 200.0
@export var jump_velocity: float = -400.0
@export var acceleration: float = 2000.0
@export var friction: float = 1000.0

#Player stats
@export var max_health: int = 100
@export var health: int = 100

# Get the gravity from the project settings to be synced with RigidBody nodes
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

# State vars
var can_double_jump = false  # double jump checker
var original_radius: float = 0.0  # slide state vars
var original_height: float = 0.0  # slide state vars
var original_position: Vector2 = Vector2.ZERO  # slide state vars
var hit_direction = 1.0  # Direction the player was hit from (positive = right, negative = left)
var can_control = true   # Whether the player can be controlled (disabled during hurt state)

@onready var sprite = $Sprite2D
@onready var animation_player = $AnimationPlayer
@onready var state_machine = $StateMachine

# The physics_process is now much simpler as states handle the logic
func _physics_process(_delta):
	# No logic here, it's all in the states
	pass

func fall_through_platforms():
	# Set velocity downward to start falling
	velocity.y = 10
	
	# Get the current position
	var _current_pos = global_position
	
	# Move character down slightly to clear the platform collision
	global_position.y += 1
	
	# Force platform detection to update
	move_and_slide()

func take_damage(amount: int, attacker_position: Vector2 = Vector2.ZERO):
	# Skip damage if player is already in hurt state
	if state_machine.current_state.name.to_lower() == "hurt":
		return
		
	health -= amount
	print("Player took ", amount, " damage! Health: ", health)
	
	# Determine hit direction (from attacker to player)
	if attacker_position != Vector2.ZERO:
		hit_direction = sign(global_position.x - attacker_position.x)
		if hit_direction == 0:
			hit_direction = 1.0  # Default right if directly above/below
	else:
		# If no attacker position provided, use opposite of player facing
		hit_direction = 1.0 if sprite.flip_h else -1.0
	
	# Transition to hurt state
	state_machine.transition_to("hurt")
	
	# Check if player has died
	if health <= 0:
		health = 0
		print("Player died!")
		# You can handle death here (could transition to a death state)
		# For now, just reset health
		health = max_health

func _on_animation_player_animation_finished(anim_name):
	# Check if it's an attack animation that finished
	if anim_name.begins_with("attack"):
		# Check if we're in the attack state
		if state_machine.current_state.name == "Attack":
			var attack_state = state_machine.states["attack"]
			# Try to continue to next combo
			if not attack_state.next_combo():
				# If no next combo, return to appropriate state
				if is_on_floor():
					state_machine.transition_to("idle")
				else:
					state_machine.transition_to("fall")
