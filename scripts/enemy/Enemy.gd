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
var original_sprite_position_x: float = 0.0

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
	
	# Store the original sprite X position
	original_sprite_position_x = sprite.position.x
	
	# Adjust the detection area
	var detection_shape = detection_area.get_node("CollisionShape2D")
	if detection_shape and detection_shape.shape is CircleShape2D:
		detection_shape.shape.radius = detection_range
	
	# Connect detection signals
	detection_area.connect("body_entered", Callable(self, "_on_detection_area_body_entered"))
	detection_area.connect("body_exited", Callable(self, "_on_detection_area_body_exited"))

func update_facing(direction: float):
	if direction == 0:
		return
		
	sprite.flip_h = (direction < 0)
	sprite.position.x = original_sprite_position_x * (1 if direction > 0 else -1)

func _on_detection_area_body_entered(body):
	if body.is_in_group("player"):
		player_detected = true
		target = body

func _on_detection_area_body_exited(body):
	if body.is_in_group("player"):
		player_detected = false
		# Keep the target reference so we can track last known position

func _physics_process(delta):
	# Apply gravity if not on floor
	if not is_on_floor():
		velocity.y += gravity * delta
	
	# The actual behavior will be in the state scripts
	move_and_slide()
	
# Functions for receiving damage
func take_damage(amount: int):
	health -= amount
	if health <= 0:
		die()
	else:
		# Play hit animation/sound
		if animation_player.has_animation("hit"):
			animation_player.play("hit")

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
		body.take_damage(damage)
