extends CharacterBody2D

# States enum
enum State {IDLE, WANDER, CHASE, ATTACK, HIT, DEAD}

# Current state
var current_state = State.IDLE

# Enemy Stats
@export var max_health: int = 80
@export var health: int = 80
@export var damage: int = 15
@export var movement_speed: float = 70.0
@export var attack_range: float = 100.0
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
var idle_timer: float = 0.0
var wander_timer: float = 0.0
var wander_direction: int = 0
var attack_timer: float = 0.0
var hit_timer: float = 0.0
var attack_cooldown: float = 1.0
var hit_cooldown: float = 0.5
var death_animation_started = false

# Node references
@onready var sprite: Sprite2D = $Sprite2D
@onready var animation_player: AnimationPlayer = $AnimationPlayer
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
	
	# Connect signals
	detection_area.body_entered.connect(_on_detection_area_body_entered)
	detection_area.body_exited.connect(_on_detection_area_body_exited)
	attack_box.body_entered.connect(_on_attack_box_body_entered)
	
	# Ensure attack box is initially disabled
	if attack_box.has_node("CollisionShape2D"):
		attack_box.get_node("CollisionShape2D").disabled = true

func _physics_process(delta):
	# Apply gravity if not on floor
	if not is_on_floor():
		velocity.y += gravity * delta
	
	# Handle states
	match current_state:
		State.IDLE:
			_handle_idle_state(delta)
		State.WANDER:
			_handle_wander_state(delta)
		State.CHASE:
			_handle_chase_state(delta)
		State.ATTACK:
			_handle_attack_state(delta)
		State.HIT:
			_handle_hit_state(delta)
		State.DEAD:
			_handle_dead_state(delta)
	
	# Apply movement
	move_and_slide()

func _handle_idle_state(delta):
	# Play idle animation
	animation_player.play("idle")
	
	# Stop horizontal movement
	velocity.x = move_toward(velocity.x, 0, friction * delta)
	
	# Increment timer
	idle_timer += delta
	
	# Check if the player is within detection range
	if player_detected and target != null:
		current_state = State.CHASE
		idle_timer = 0.0
		return
	
	# After idle duration, transition to wander
	if idle_timer >= 3.0:
		current_state = State.WANDER
		wander_timer = 0.0
		wander_direction = [-1, 1][randi() % 2]
		update_facing(wander_direction)
		return

func _handle_wander_state(delta):
	# Play walk animation
	animation_player.play("walk")
	
	# Move in the chosen direction
	var target_velocity = wander_direction * movement_speed
	velocity.x = move_toward(velocity.x, target_velocity, acceleration * delta)
	
	# Increment timer
	wander_timer += delta
	
	# Check if the player is within detection range
	if player_detected and target != null:
		current_state = State.CHASE
		wander_timer = 0.0
		return
	
	# Check if we've wandered too far from spawn point
	var distance_from_spawn = global_position.distance_to(spawn_position)
	if distance_from_spawn > wander_range:
		# Turn around and head back
		wander_direction = 1 if spawn_position.x > global_position.x else -1
		update_facing(wander_direction)
	
	# Check for obstacles or edges
	if is_on_wall():
		# Turn around
		wander_direction *= -1
		update_facing(wander_direction)
	
	# After wander duration, transition to idle
	if wander_timer >= 2.0:
		current_state = State.IDLE
		idle_timer = 0.0
		return

func _handle_chase_state(delta):
	# Play walk/run animation
	animation_player.play("walk")
	
	# Make sure we have a valid target
	if target == null:
		current_state = State.IDLE
		idle_timer = 0.0
		return
	
	# Check if player is still detected
	if not player_detected:
		current_state = State.IDLE
		idle_timer = 0.0
		return
	
	# Get direction to player
	var direction = sign(target.global_position.x - global_position.x)
	
	# Update sprite direction
	update_facing(direction)
	
	# Move towards player
	var target_velocity = direction * movement_speed
	velocity.x = move_toward(velocity.x, target_velocity, acceleration * delta)
	
	# Check if we're close enough to attack
	var distance_to_target = global_position.distance_to(target.global_position)
	if distance_to_target <= attack_range and can_attack:
		current_state = State.ATTACK
		attack_timer = 0.0
		return
	
	# Check if we've gone too far from spawn point
	var spawn_distance = global_position.distance_to(spawn_position)
	if spawn_distance > wander_range * 1.5:
		player_detected = false
		current_state = State.IDLE
		idle_timer = 0.0
		return

func _handle_attack_state(delta):
	# Choose between attack animations based on random factor
	if attack_timer == 0:
		if randf() < 0.7:  # 70% chance to use attackA
			animation_player.play("attackA")
		else:
			animation_player.play("attackB")
		
		# Stop movement
		velocity.x = 0
	
	# Increment attack timer
	attack_timer += delta
	
	# Make sure we have a valid target
	if target == null:
		current_state = State.IDLE
		idle_timer = 0.0
		return
	
	# Face the player
	var direction = sign(target.global_position.x - global_position.x)
	if direction != 0:
		update_facing(direction)
	
	# Keep the enemy in place during attack
	velocity.x = move_toward(velocity.x, 0, friction * delta)
	
	# Wait for animation to finish
	if not animation_player.is_playing():
		# Reset attack cooldown
		can_attack = false
		
		# Explicitly disable the attack box collision shape
		if attack_box and attack_box.has_node("CollisionShape2D"):
			attack_box.get_node("CollisionShape2D").disabled = true
		
		# Start a timer to re-enable attacks
		var timer = get_tree().create_timer(attack_cooldown)
		timer.timeout.connect(func(): can_attack = true)
		
		# After attack animation completes, transition to chase
		if target and player_detected:
			current_state = State.CHASE
		else:
			current_state = State.IDLE
			idle_timer = 0.0

func _handle_hit_state(delta):
	# Only play hit animation once
	if hit_timer == 0:
		animation_player.play("hit")
	
	# Increment hit timer
	hit_timer += delta
	
	# Apply a small knockback
	velocity.x = move_toward(velocity.x, 0, friction * delta)
	
	# Wait for animation to finish or timer to expire
	if hit_timer >= hit_cooldown:
		hit_timer = 0.0
		
		# If we were chasing the player, resume chase
		if player_detected and target != null:
			current_state = State.CHASE
		else:
			current_state = State.IDLE
			idle_timer = 0.0

func _handle_dead_state(_delta):
	# Only play death animation once
	if not death_animation_started:
		death_animation_started = true
		animation_player.play("dead")
		
		# Connect the animation_finished signal if not already connected
		if not animation_player.animation_finished.is_connected(_on_death_animation_finished):
			animation_player.animation_finished.connect(_on_death_animation_finished)
	
	# We want to keep collision with the floor but disable other interactions
	set_collision_layer_value(2, false)  # Disable enemy layer
	set_collision_mask_value(2, false)   # Disable interaction with player
	
	# Freeze horizontal movement
	velocity.x = 0

func _on_death_animation_finished(anim_name):
	print("Animation finished: ", anim_name)
	if anim_name == "dead":
		print("Death animation completed, starting fade")
		# Start fading out
		var tween = create_tween()
		tween.tween_property(sprite, "modulate:a", 0.0, 1.0)  # Fade out over 1 second
		# Add a debug print before the queue_free call
		tween.tween_callback(func(): print("Tween completed, about to queue_free"); queue_free())

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

func take_damage(amount: int):
	health -= amount
	
	if health <= 0:
		current_state = State.DEAD
	else:
		# Interrupt current actions and enter hit state
		current_state = State.HIT
		hit_timer = 0.0
		
		# Apply a small knockback
		velocity.x = -facing_direction * 100

func _on_detection_area_body_entered(body):
	if body.is_in_group("player"):
		player_detected = true
		target = body
		
		# Only transition to chase if we're in idle or wander state
		if current_state == State.IDLE or current_state == State.WANDER:
			current_state = State.CHASE

func _on_detection_area_body_exited(body):
	if body.is_in_group("player"):
		player_detected = false
		# Keep the target reference so we can track last known position

func _on_attack_box_body_entered(body):
	if body.is_in_group("player") and body.has_method("take_damage") and current_state == State.ATTACK:
		# Pass our position to determine hit direction
		body.take_damage(damage, global_position)

func drop_loot():
	# Spawn coins or other loot here when implemented
	pass
