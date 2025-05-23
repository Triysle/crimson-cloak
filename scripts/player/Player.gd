extends CharacterBody2D

# Player movement variables
@export var speed: float = 200.0
@export var jump_velocity: float = -400.0
@export var acceleration: float = 2000.0
@export var friction: float = 1000.0

# Player stats
@export var max_health: int = 100
@export var health: int = 100
@export var max_healing_charges: int = 5
@export var healing_charges: int = 1
@export var healing_amount: int = 25

# Additional player variables for new features
var gravity_enabled: bool = true  # Whether gravity should be applied (disabled during climbing)
var stamina: float = 100.0        # Stamina for hanging and special moves
var max_stamina: float = 100.0    # Maximum stamina
var stamina_regen_rate: float = 10.0  # Stamina regeneration per second

# References to managers
@onready var player_manager = get_node("/root/PlayerManager")
@onready var inventory_manager = get_node("/root/InventoryManager")

# Get the gravity from the project settings to be synced with RigidBody nodes
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

# State vars
var can_double_jump = false  # double jump checker
var original_radius: float = 0.0  # slide state vars
var original_height: float = 0.0  # slide state vars
var original_position: Vector2 = Vector2.ZERO  # slide state vars
var hit_direction = 1.0  # Direction the player was hit from (positive = right, negative = left)
var can_control = true   # Whether the player can be controlled (disabled during hurt state)

# Ladder detection variables
var current_ladder = null          # Reference to the ladder being climbed
var ladder_overlap_count = 0       # Count of ladders player is overlapping

# Debug variables
var debug_timer = 0.0

# HUD variables
var currency = 0
var hud = null

@onready var sprite = $Sprite2D
@onready var animation_player = $AnimationPlayer
@onready var state_machine = $StateMachine

# Preload the dust effect scene
const DustEffect = preload("res://scenes/player/DustEffect.tscn")

func _ready():
	# Set up attack box connection
	var attack_box = $AttackBox
	if attack_box and !attack_box.body_entered.is_connected(_on_attack_box_body_entered):
		attack_box.body_entered.connect(_on_attack_box_body_entered)
	
	# Set up collision shapes for crouching
	var crouch_collider = $CrouchCollider
	var normal_collider = $NormalCollider
	
	if crouch_collider and normal_collider:
		# Make sure only the normal collider is enabled at start
		normal_collider.disabled = false
		crouch_collider.disabled = true

	# Find the HUD in the scene
	await get_tree().process_frame
	hud = get_tree().get_first_node_in_group("hud")
	
	# Get direct reference to our HUD child
	hud = $HUD
	
	# Update HUD with initial values
	if hud:
		hud.update_health(health, max_health)
		hud.update_currency(currency)
		hud.update_healing_charges(healing_charges, max_healing_charges)
		if hud.has_method("update_stamina"):
			hud.update_stamina(stamina, max_stamina)

# Physics process function
func _physics_process(delta):
	# Apply gravity if enabled and not on floor
	if gravity_enabled and not is_on_floor():
		velocity.y += gravity * delta

# Function to make the player drop through one-way platforms
func fall_through_platforms():
	# Set velocity downward to start falling
	velocity.y = 10
	
	# Get the current position
	var _current_pos = global_position
	
	# Move character down slightly to clear the platform collision
	global_position.y += 1
	
	# Force platform detection to update
	move_and_slide()

# Function to handle taking damage
func take_damage(amount: int, attacker_position: Vector2 = Vector2.ZERO):
	# Get the current state
	var current_state = state_machine.current_state.name.to_lower()
	
	# Check if player is currently blocking
	if current_state == "block" or current_state == "crouchblock":
		# Use the block state's damage handling
		state_machine.current_state.take_block_damage(amount, attacker_position)
		return
	
	# Skip damage if player is already in hurt state
	if current_state == "hurt":
		return
		
	health -= amount
	print("Player took ", amount, " damage! Health: ", health)

	# Update the HUD
	if hud:
		hud.update_health(health, max_health)
	
	# Determine hit direction (from attacker to player)
	if attacker_position != Vector2.ZERO:
		hit_direction = sign(global_position.x - attacker_position.x)
		if hit_direction == 0:
			hit_direction = 1.0  # Default right if directly above/below
	else:
		# If no attacker position provided, use opposite of player facing
		hit_direction = 1.0 if sprite.flip_h else -1.0
	
	# Check if player has died
	if health <= 0:
		die()
		return
	
	# If not dead, transition to hurt state
	state_machine.transition_to("hurt")

# Handle animation finished events
func _on_animation_player_animation_finished(anim_name):
	# Check if it's an attack animation that finished
	if anim_name.begins_with("attack"):
		# Check if we're in the attack state
		if state_machine.current_state.name.to_lower() == "attack":
			var attack_state = state_machine.states["attack"]
			# Try to continue to next combo
			if not attack_state.next_combo():
				# If no next combo, return to appropriate state
				if is_on_floor():
					state_machine.transition_to("idle")
				else:
					state_machine.transition_to("fall")

# Function to start climbing a ladder
func start_climbing(ladder):
	if state_machine.states.has("climb"):
		current_ladder = ladder
		var climb_state = state_machine.states["climb"]
		climb_state.set_ladder(ladder)
		
		# Transition to climb state
		state_machine.transition_to("climb")

# Function to stop climbing
func stop_climbing():
	current_ladder = null
	
	# Transition to appropriate state based on whether player is on floor
	if is_on_floor():
		state_machine.transition_to("idle")
	else:
		state_machine.transition_to("fall")

# Stamina functions
func drain_stamina(amount: float):
	stamina = max(0, stamina - amount)
	
	# Update stamina UI if available
	if hud and hud.has_method("update_stamina"):
		hud.update_stamina(stamina, max_stamina)

func regenerate_stamina(delta: float):
	if stamina < max_stamina:
		stamina = min(max_stamina, stamina + stamina_regen_rate * delta)
		
		# Update stamina UI if available
		if hud and hud.has_method("update_stamina"):
			hud.update_stamina(stamina, max_stamina)

# Connect to ladder area
func _on_ladder_detector_area_entered(area):
	if area.is_in_group("ladder"):
		ladder_overlap_count += 1
		
		# Store reference to the ladder
		if current_ladder == null:
			current_ladder = area

func _on_ladder_detector_area_exited(area):
	if area.is_in_group("ladder"):
		ladder_overlap_count -= 1
		
		# If no more ladders, clear the reference
		if ladder_overlap_count <= 0:
			ladder_overlap_count = 0
			current_ladder = null
			
			# If currently climbing, stop climbing
			if state_machine.current_state.name.to_lower() == "climb":
				stop_climbing()

func _on_attack_box_body_entered(body):
	print("Attack box hit: ", body.name)
	print("Is in group enemy: ", body.is_in_group("enemy"))
	print("Current state: ", state_machine.current_state.name)
	
	if body.is_in_group("enemy") and state_machine.current_state.name.to_lower() == "attack":
		print("Enemy hit confirmed!")
		# Get the current attack state
		var attack_state = state_machine.states["attack"]
		
		# Make sure we don't hit the same enemy multiple times in one attack
		if attack_state.hit_enemies.has(body):
			print("Enemy already hit this attack")
			return
			
		attack_state.hit_enemies.append(body)
		
		# Calculate damage based on current attack in combo
		var damage = 10  # Base damage
		if attack_state.current_attack == 2:
			damage = 15
		elif attack_state.current_attack == 3:
			damage = 20
			
		print("Dealing damage: ", damage)
			
		# Call the enemy's take_damage method
		if body.has_method("take_damage"):
			body.take_damage(damage)
		else:
			print("Enemy doesn't have take_damage method")
	else:
		print("No hit processed. Is enemy: ", body.is_in_group("enemy"), " Is attacking: ", state_machine.current_state.name.to_lower() == "attack")

# Function to spawn dust effect
func spawn_dust_effect(animation_name: String):
	# Create instance of dust effect
	var dust = DustEffect.instantiate()
	# Set position to player's feet
	dust.global_position = global_position + Vector2(0, -20)
	# Play the specified animation
	dust.play(animation_name)
	# Add to the current scene
	get_tree().current_scene.add_child(dust)

func add_currency(amount: int):
	# Update the inventory manager
	inventory_manager.add_currency(amount)
	
	# Update our local currency variable
	currency = inventory_manager.currency
	
	# Update the HUD
	if hud:
		hud.update_currency(currency)

func set_ability(ability_texture):
	# Update the HUD
	if hud:
		hud.set_ability_icon(ability_texture)

func use_healing():
	if healing_charges > 0 and health < max_health:
		healing_charges -= 1
		health += healing_amount
		
		# Cap health at maximum
		if health > max_health:
			health = max_health
			
		# Update the HUD
		if hud:
			hud.update_health(health, max_health)
			hud.update_healing_charges(healing_charges, max_healing_charges)
		
		return true  # Successfully used healing
	
	return false  # Could not use healing

func add_healing_charge(amount: int = 1):
	healing_charges += amount
	
	# Cap at maximum
	if healing_charges > max_healing_charges:
		healing_charges = max_healing_charges
		
	# Update the HUD
	if hud:
		hud.update_healing_charges(healing_charges, max_healing_charges)

func _input(event):
	# Check for healing input
	if event.is_action_pressed("heal"):
		use_healing()
		
	# Check for ladder climbing
	if current_ladder and event.is_action_pressed("move_up"):
		start_climbing(current_ladder)
		
	# Debug suicide button
	if event.is_action_pressed("debug_die"):
		die()

func heal_to_full():
	# Restore health to maximum
	health = max_health
	print("Player healed to full health!")
	
	# Update the HUD
	if hud:
		hud.update_health(health, max_health)

func respawn_at(respawn_position: Vector2):
	# Reset player state
	health = max_health
	velocity = Vector2.ZERO
	can_control = false
	
	# Set player position to respawn point
	global_position = respawn_position
	
	# Update the HUD
	if hud:
		hud.update_health(health, max_health)
	
	# Transition to spawn state
	state_machine.transition_to("spawn")

func die():
	# Disable player control
	can_control = false
	
	# Set health to 0
	health = 0
	
	# Update HUD
	if hud:
		hud.update_health(health, max_health)
	
	# Transition to death state instead of playing animation directly
	state_machine.transition_to("death")
	
	# Notify the PlayerManager
	player_manager.on_player_death()
