extends Node2D

# Configuration
@export var max_shadows: int = 5
@export var shadow_delay: float = 0.05  # Time between shadow spawns
@export var fade_time: float = 0.3  # How long shadows take to fade out
@export var shadow_color: Color = Color(0.2, 0.2, 0.5, 0.5)  # Bluish transparent color
@export var movement_threshold: float = 10.0  # Only spawn shadows when moving fast enough

# Variables
var shadow_timer: float = 0
var player: CharacterBody2D
var player_sprite: Sprite2D
var last_position: Vector2 = Vector2.ZERO

func _ready():
	# Reference to the player (parent)
	player = get_parent()
	player_sprite = player.get_node("Sprite2D")
	last_position = player.global_position
	
	# Set up the spawn timer
	shadow_timer = 0  # Start creating shadows immediately

func _process(delta):
	# Update timer
	shadow_timer -= delta
	
	# If it's time to spawn a new shadow and we're moving
	if shadow_timer <= 0 and is_moving_fast_enough():
		_spawn_shadow()
		shadow_timer = shadow_delay
		last_position = player.global_position

func is_moving_fast_enough() -> bool:
	# Only spawn shadows when the player is moving at a certain speed
	return player.global_position.distance_to(last_position) > movement_threshold * shadow_timer

func _spawn_shadow():
	# Create a new Sprite2D for the shadow
	var shadow = Sprite2D.new()
	
	# Copy sprite properties from player
	shadow.texture = player_sprite.texture
	shadow.hframes = player_sprite.hframes
	shadow.vframes = player_sprite.vframes
	shadow.frame = player_sprite.frame
	shadow.flip_h = player_sprite.flip_h
	
	# Set shadow position exactly where the player sprite is
	shadow.global_position = player_sprite.global_position
	shadow.z_index = player_sprite.z_index - 1  # Make sure shadow is behind player
	
	# Add to the current scene instead of this node
	get_tree().current_scene.add_child(shadow)
	
	# Set properties for fading
	shadow.modulate = shadow_color
	
	# Create a tween for fading out the shadow
	var tween = create_tween()
	tween.tween_property(shadow, "modulate:a", 0.0, fade_time)
	tween.tween_callback(shadow.queue_free)
