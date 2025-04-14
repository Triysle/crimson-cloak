extends CanvasLayer

@onready var health_bar = $Background/HealthBar
@onready var coin_count = $Background/CoinDisplay/CoinCounter
@onready var ability_icon = $Background/Panel/AbilityIcon
@onready var health_containers = $Background/HealthContainers

# Track how many healing charges the player has
var max_healing_charges = 5
var current_healing_charges = 1

func _ready():
	# Initialize the HUD
	pass

func update_health(current_health, max_health):
	# Update the health bar value
	health_bar.max_value = max_health
	health_bar.value = current_health

func update_currency(amount):
	coin_count.text = str(amount)

func set_ability_icon(texture):
	ability_icon.texture = texture

func update_healing_charges(current, maximum):
	current_healing_charges = current
	max_healing_charges = maximum
	
	# Update the visual representation of healing charges
	for i in range(health_containers.get_child_count()):
		var container = health_containers.get_child(i)
		
		# Show/hide based on max charges
		container.visible = i < max_healing_charges
		
		# Set the appropriate texture based on current charges
		if i < current_healing_charges:
			container.texture = preload("res://assets/ui/health/HealthSegmentFull.png")
		else:
			container.texture = preload("res://assets/ui/health/HealthSegmentEmpty.png")
