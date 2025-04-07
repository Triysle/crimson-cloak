extends CharacterBody2D

# Movement parameters
@export var speed = 200
@export var jump_force = 400
@export var gravity = 980

# Combat parameters
@export var max_health = 100
@export var current_health = 100
@export var max_stamina = 100
@export var current_stamina = 100
@export var stamina_regen_rate = 10
@export var attack_stamina_cost = 20

# State tracking
var is_attacking = false
var is_blocking = false

@onready var sprite = $Sprite2D
@onready var animation_player = $AnimationPlayer
@onready var animation_tree = $AnimationTree

func _ready():
	# Initialize animation tree
	animation_tree.active = true

func _physics_process(delta):
	# Apply gravity
	if not is_on_floor():
		velocity.y += gravity * delta
	
	# Handle jump
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = -jump_force
	
	# Get movement direction
	var direction = Input.get_axis("move_left", "move_right")
	
	# Handle movement
	if direction != 0:
		velocity.x = direction * speed
		# Flip sprite based on direction
		if direction < 0:
			sprite.flip_h = true
		else:
			sprite.flip_h = false
	else:
		# Slow down when no direction is pressed
		velocity.x = move_toward(velocity.x, 0, speed)
	
	# Handle attack input
	if Input.is_action_just_pressed("attack") and current_stamina >= attack_stamina_cost:
		attack()
	
	# Handle block input
	is_blocking = Input.is_action_pressed("block") and is_on_floor() and current_stamina > 0
	
	# Regenerate stamina
	if not is_attacking and not is_blocking:
		current_stamina = min(current_stamina + stamina_regen_rate * delta, max_stamina)
	elif is_blocking:
		current_stamina = max(current_stamina - stamina_regen_rate * 0.5 * delta, 0)
	
	# Update animations
	update_animation()
	
	# Apply movement
	move_and_slide()

func update_animation():
	# Update animation parameters in the animation tree
	var state = "idle"
	
	if not is_on_floor():
		if velocity.y < 0:
			state = "jump"
		else:
			state = "fall"
	elif is_attacking:
		state = "attack"
	elif is_blocking:
		state = "block"
	elif abs(velocity.x) > 10:
		state = "run"
	
	# Set the parameters in the animation tree
	animation_tree.set("parameters/state/current", state)

func attack():
	is_attacking = true
	current_stamina -= attack_stamina_cost
	# Attack logic will go here
	# We'll implement this with animations later
	
	# Reset attack state after animation finishes
	await get_tree().create_timer(0.4).timeout
	is_attacking = false

func take_damage(amount):
	if is_blocking:
		# Reduce damage when blocking
		amount = amount / 2
	
	current_health = max(current_health - amount, 0)
	
	if current_health <= 0:
		die()

func die():
	# Death logic
	print("Player died")
	# You might want to play a death animation and restart the level

# Called when player successfully hits an enemy
func on_hit_enemy(enemy):
	# Hit logic, maybe add effects or restore stamina
	pass
