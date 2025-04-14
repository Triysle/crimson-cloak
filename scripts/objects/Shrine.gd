extends Area2D

signal shrine_activated

@export var pulse_color: Color = Color(0.8, 0.0, 0.0, 1.0)  # Red color
@export var dormant_pulse_max: float = 0.2                 # Maximum pulse intensity when dormant (20%)
@export var dormant_pulse_period: float = 2.0              # Time for one complete pulse cycle when dormant
@export var healing_amount: int = 100                      # Amount to heal
@export var restore_charges: bool = true                   # Whether to restore healing charges

var player_in_range: bool = false
var pulse_time: float = 0.0
var original_material: ShaderMaterial
var shrine_state: String = "dormant"  # Can be "dormant", "activating", "active", "fading"
var activation_timer: float = 0.0

func _ready():
	# Create shader material for the sprite
	var sprite = $Sprite2D
	
	# Create a new shader material
	original_material = ShaderMaterial.new()
	original_material.shader = preload("res://scripts/shaders/ShrinePulseShader.gdshader")
	original_material.set_shader_parameter("pulse_color", pulse_color)
	original_material.set_shader_parameter("pulse_amount", 0.0)
	
	# Apply material to sprite
	sprite.material = original_material
	
	# Connect signals
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _process(delta):
	match shrine_state:
		"dormant":
			# Slow breathing pulse between 0 and dormant_pulse_max
			pulse_time += delta / dormant_pulse_period
			var pulse_amount = sin(pulse_time * PI) * dormant_pulse_max
			original_material.set_shader_parameter("pulse_amount", max(0, pulse_amount))
			
		"activating":
			# Surge to full intensity over 1 second
			activation_timer += delta
			var t = min(activation_timer, 1.0)
			original_material.set_shader_parameter("pulse_amount", t)
			
			if activation_timer >= 1.0:
				shrine_state = "active"
				activation_timer = 0.0
				
		"active":
			# Rapid pulsing at high intensity for 1 second
			activation_timer += delta
			var pulse_amount = 0.8 + sin(activation_timer * 15.0) * 0.2  # Pulse between 0.6 and 1.0
			original_material.set_shader_parameter("pulse_amount", pulse_amount)
			
			if activation_timer >= 1.0:
				shrine_state = "fading"
				activation_timer = 0.0
				
		"fading":
			# Fade back to dormant state over 1 second
			activation_timer += delta
			var t = 1.0 - min(activation_timer, 1.0)
			var dormant_pulse = sin(pulse_time * PI) * dormant_pulse_max
			var pulse_amount = max(dormant_pulse, t)
			original_material.set_shader_parameter("pulse_amount", pulse_amount)
			
			if activation_timer >= 1.0:
				shrine_state = "dormant"
				activation_timer = 0.0

func _on_body_entered(body):
	if body.is_in_group("player"):
		player_in_range = true

func _on_body_exited(body):
	if body.is_in_group("player"):
		player_in_range = false

func _input(event):
	if player_in_range and event.is_action_pressed("move_up"):
		activate_shrine()

func activate_shrine():
	# Only activate if currently dormant
	if shrine_state == "dormant":
		shrine_state = "activating"
		activation_timer = 0.0
		
		# Emit signal for saving game
		shrine_activated.emit()
		
		# Heal the player if in range
		var player = get_tree().get_first_node_in_group("player")
		if player:
			if player.has_method("heal_to_full"):
				player.heal_to_full()
			elif player.has_method("take_damage"):
				player.take_damage(-healing_amount)
			
			# Restore healing charges
			if restore_charges and player.has_method("add_healing_charge"):
				player.add_healing_charge(player.max_healing_charges)
