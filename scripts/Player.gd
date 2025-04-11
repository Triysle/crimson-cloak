extends CharacterBody2D

# Player movement variables
@export var speed: float = 200.0
@export var jump_velocity: float = -400.0
@export var acceleration: float = 2000.0
@export var friction: float = 1000.0

# Get the gravity from the project settings to be synced with RigidBody nodes
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

# State vars
var can_double_jump = false  # double jump checker
var original_radius: float = 0.0  # slide state vars
var original_height: float = 0.0  # slide state vars
var original_position: Vector2 = Vector2.ZERO  # slide state vars

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
