extends Node2D

# Door identification
@export var door_name: String = "Door"
@export var target_door: String = ""
@export var target_scene: String = ""

# Interaction properties
@export var requires_key: String = ""  # Empty string means no key required
@export var activates_on_touch: bool = false  # If false, requires "up" press

# Optional signal for effects, animations, etc.
signal door_activated

# Reference to the player
var player = null
# Cooldown to prevent immediate re-activation
var active: bool = true
var cooldown_timer: float = 0.5

func _ready():
	# Connect to the area's body detection signals
	var area = $Area2D
	area.body_entered.connect(_on_body_entered)
	area.body_exited.connect(_on_body_exited)
	
	# Check if this is a target door from a transition
	if SceneTransition.target_door == door_name:
		# Disable the door temporarily to prevent immediate activation
		active = false
		# Create a timer to re-enable the door
		create_tween().tween_callback(func(): active = true).set_delay(cooldown_timer)

func _on_body_entered(body):
	if body.is_in_group("player") and active:
		player = body
		
		# If door activates on touch, trigger immediately
		if activates_on_touch:
			use_door()

func _on_body_exited(body):
	if body.is_in_group("player"):
		player = null

func _input(event):
	# Only process input if player is in range and door doesn't activate on touch
	if player and not activates_on_touch and active:
		if event.is_action_pressed("move_up"):
			use_door()

func use_door():
	# Check if key is required
	if requires_key != "":
		# Check if player has the key (you'll need to implement inventory system)
		if not player.has_key(requires_key):
			# Notify player they need a key
			print("You need the " + requires_key + " to open this door!")
			return
	
	# Door is usable, emit signal for effects
	door_activated.emit()
	
	# Handle scene transition
	if target_scene != "":
		call_deferred("_change_scene")

func _change_scene():
	# Get the SceneTree to change the scene
	var scene_tree = get_tree()
	
	# Store the target door for the new scene to use
	SceneTransition.last_door_name = door_name
	SceneTransition.target_door = target_door
	
	# Change to the target scene
	scene_tree.change_scene_to_file(target_scene)
