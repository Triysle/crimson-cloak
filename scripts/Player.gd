extends CharacterBody2D

# Player movement variables
@export var speed: float = 300.0
@export var jump_velocity: float = -400.0
@export var acceleration: float = 2000.0
@export var friction: float = 1000.0

# Get the gravity from the project settings to be synced with RigidBody nodes
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

# State checks
var can_double_jump = false

@onready var sprite = $Sprite2D
@onready var animation_player = $AnimationPlayer
@onready var state_machine = $StateMachine

# The physics_process is now much simpler as states handle the logic
func _physics_process(_delta):
	# No logic here, it's all in the states
	pass
