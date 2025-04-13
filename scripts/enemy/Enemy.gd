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
var current_state_name: String = "idle"  # Track current state
var idle_timer: float = 0.0

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

func update_facing(direction: float):
	if direction == 0:
		return
	
	var new_facing = 1 if direction > 0 else -1
	
	# Only update if facing direction changed
	if new_facing != facing_direction:
		facing_direction = new_facing
		
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
		
		# Only transition to chase if we're in idle or wander state
		if current_state_name == "idle" or current_state_name == "wander":
			state_machine.transition_to("chase")

func _on_detection_area_body_exited(body):
	if body.is_in_group("player"):
		player_detected = false
		# Keep the target reference so we can track last known position

func _physics_process(delta):
	# Apply gravity if not on floor
	if not is_on_floor() and current_state_name != "attack":
		velocity.y += gravity * delta
	
	# The actual behavior will be in the state scripts
	move_and_slide()

# Functions for receiving damage
func take_damage(amount: int):
	health -= amount
	
	if health <= 0:
		die()
	else:
		# Interrupt current actions
		velocity.x = 0
		
		# Play hit animation/sound
		if animation_player.has_animation("hit"):
			animation_player.play("hit")
			
		# Add a small knockback
		velocity.x = -facing_direction * 100
		
		# Return to idle after the hit animation finishes
		await animation_player.animation_finished
		
		# If we were chasing the player, resume chase
		if player_detected and target != null:
			state_machine.transition_to("chase")
		else:
			state_machine.transition_to("idle")

func die():
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
		# Pass our position to determine hit direction
		body.take_damage(damage, global_position)
