extends CharacterBody2D
class_name Enemy

# Enemy Stats
@export var max_health: int = 100
@export var health: int = 100
@export var damage: int = 10
@export var movement_speed: float = 100.0
@export var attack_range: float = 50.0
@export var detection_range: float = 200.0
@export var wander_range: float = 100.0

# Physics properties
@export var gravity: float = 980.0
@export var acceleration: float = 1000.0
@export var friction: float = 800.0

# State tracking
var player_detected: bool = false
var can_attack: bool = true
var spawn_position: Vector2 = Vector2.ZERO
var target: Node2D = null
var facing_direction: int = 1  # 1 for right, -1 for left
var current_state_name: String = "idle"  # Track current state for debugging
var idle_timer: float = 0.0

# Debug tracking
var _last_velocity = Vector2.ZERO
var debug_enabled = true  # Set to false to disable debug prints

# Node references
@onready var sprite: Sprite2D = $Sprite2D
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var state_machine: Node = $StateMachine
@onready var detection_area: Area2D = $DetectionArea
@onready var hit_box: Area2D = $HitBox
@onready var attack_box: Area2D = $AttackBox

func _ready():
	# Store the initial spawn position
	spawn_position = global_position
	
	# Store initial velocity for debugging
	_last_velocity = velocity
	
	# Set initial facing direction
	facing_direction = 1
	
	# Adjust the detection area
	var detection_shape = detection_area.get_node("CollisionShape2D")
	if detection_shape and detection_shape.shape is CircleShape2D:
		detection_shape.shape.radius = detection_range
	
	# Connect detection signals - check if not already connected
	if !detection_area.body_entered.is_connected(_on_detection_area_body_entered):
		detection_area.body_entered.connect(_on_detection_area_body_entered)
	
	if !detection_area.body_exited.is_connected(_on_detection_area_body_exited):
		detection_area.body_exited.connect(_on_detection_area_body_exited)
	
	# Connect attack box signals - check if not already connected
	if !attack_box.body_entered.is_connected(_on_attack_box_body_entered):
		attack_box.body_entered.connect(_on_attack_box_body_entered)
	
	# Ensure attack box is initially disabled
	if attack_box.has_node("CollisionShape2D"):
		attack_box.get_node("CollisionShape2D").disabled = true
	
	debug_print("Enemy initialized with movement_speed: " + str(movement_speed))

func update_facing(direction: float):
	if direction == 0:
		return
	
	var new_facing = 1 if direction > 0 else -1
	
	# Only update if facing direction changed
	if new_facing != facing_direction:
		facing_direction = new_facing
		debug_print("Changed facing direction to: " + str(facing_direction))
		
		# Update sprite facing
		sprite.flip_h = (facing_direction < 0)
		
		# We need to adjust the sprite position to maintain its original offset
		var sprite_offset = abs(sprite.position.x)
		if sprite_offset > 0:  # Only adjust if there's an actual offset
			sprite.position.x = sprite_offset * facing_direction
		
		# Update attack box position
		if attack_box and attack_box.has_node("CollisionShape2D"):
			var attack_shape = attack_box.get_node("CollisionShape2D")
			var attack_offset = abs(attack_shape.position.x)
			attack_shape.position.x = attack_offset * facing_direction

func _on_detection_area_body_entered(body):
	if body.is_in_group("player"):
		player_detected = true
		target = body
		debug_print("Player detected!")
		
		# Only transition to chase if we're in idle or wander state
		if current_state_name == "idle" or current_state_name == "wander":
			state_machine.transition_to("chase")

func _on_detection_area_body_exited(body):
	if body.is_in_group("player"):
		player_detected = false
		debug_print("Player lost from detection area")
		# Keep the target reference so we can track last known position

func _physics_process(delta):
	# Store previous velocity for debugging
	var old_velocity = velocity
	
	# Apply gravity if not on floor
	if not is_on_floor() and current_state_name != "attack":
		velocity.y += gravity * delta
	
	# Track velocity changes before move_and_slide
	if old_velocity.x != 0 and velocity.x == 0:
		debug_print("Velocity.x zeroed BEFORE move_and_slide in state: " + current_state_name)
	
	# The actual behavior will be in the state scripts
	var collision = move_and_slide()
	
	# Check if velocity was zeroed by move_and_slide
	if old_velocity.x != 0 and velocity.x == 0:
		debug_print("Velocity.x zeroed by move_and_slide. Hit something in state: " + current_state_name)
		if is_on_wall():
			debug_print("  -> Hit a wall")
	
	# Debug changes in velocity
	if _last_velocity.x != velocity.x:
		debug_print("Velocity.x changed from " + str(_last_velocity.x) + " to " + str(velocity.x) + " in state: " + current_state_name)
		_last_velocity = velocity

func debug_print(message: String):
	if debug_enabled:
		print("[Enemy:" + name + "] " + message)

# Functions for receiving damage
func take_damage(amount: int):
	health -= amount
	debug_print("Took " + str(amount) + " damage. Health: " + str(health))
	
	if health <= 0:
		die()
	else:
		# Play hit animation/sound
		if animation_player.has_animation("hit"):
			animation_player.play("hit")

func die():
	debug_print("Died")
	# Will be overridden by child classes if needed
	if animation_player.has_animation("dead"):
		animation_player.play("dead")
	
	# Disable collision and physics
	set_collision_layer_value(1, false)
	set_collision_mask_value(1, false)
	set_physics_process(false)
	
	# Wait for animation then free the node
	await animation_player.animation_finished
	queue_free()
	
# Function for dropping loot when defeated
func drop_loot():
	# Will be implemented in child classes
	pass

func _on_attack_box_body_entered(body):
	if body.is_in_group("player") and body.has_method("take_damage"):
		debug_print("Attack hit player")
		body.take_damage(damage)
