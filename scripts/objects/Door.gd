extends Area2D

# Original door properties
@export var door_name: String = "Door"
@export var target_scene: String = ""
@export var target_door: String = ""
@export var required_key: String = ""
@export var auto_transition: bool = false
# New spawn point property
@export_enum("Right", "Center", "Left") var spawn_point_position = "Center"

# References to managers
@onready var level_manager = get_node("/root/LevelManager")
@onready var inventory_manager = get_node("/root/InventoryManager")
@onready var spawn_point = $SpawnPoint

func _ready():
	# Set the spawn point position based on the selected option
	match spawn_point_position:
		"Right":
			spawn_point.position.x = 24
		"Center":
			spawn_point.position.x = 0
		"Left":
			spawn_point.position.x = -24
	
	# Connect signals
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _on_body_entered(body):
	if body.is_in_group("player"):
		# If auto transition, immediately transfer the player
		if auto_transition:
			if required_key != "" and not inventory_manager.has_key(required_key):
				print("This door is locked and requires the " + required_key + ".")
				return
			level_manager.transition_to_scene(target_scene, target_door)
		else:
			# Enable input detection for manual doors
			level_manager.set_active_door(self)

func _process(_delta):
	# For manual doors, check if player presses "up" while inside door area
	if not auto_transition and level_manager.active_door == self:
		if Input.is_action_just_pressed("move_up"):
			if required_key != "" and not inventory_manager.has_key(required_key):
				print("This door is locked and requires the " + required_key + ".")
				return
			level_manager.transition_to_scene(target_scene, target_door)

func _on_body_exited(body):
	if body.is_in_group("player") and not auto_transition:
		# Clear active door reference when player leaves
		if level_manager.active_door == self:
			level_manager.set_active_door(null)
			
# Get the spawn position in global coordinates
func get_spawn_position():
	return spawn_point.global_position
