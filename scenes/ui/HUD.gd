extends CanvasLayer

@onready var health_bar = $Background/HealthBar
@onready var coin_count = $Background/CoinDisplay/CoinCounter
@onready var ability_icon = $Background/Panel/AbilityIcon

# References to health container icons (if you've added them)
var health_containers = []

func _ready():
	# Get references to health container icons if they exist
	for container in $MarginContainer/HBoxContainer/VBoxContainer/HealthContainers.get_children():
		health_containers.append(container)

func update_health(current_health, max_health):
	# Update the health bar value
	health_bar.max_value = max_health
	health_bar.value = current_health
	
	# Update health containers if implemented
	if health_containers.size() > 0:
		for i in range(health_containers.size()):
			if i < 5:  # Assuming a maximum of 5 health containers
				health_containers[i].visible = true
				# Show filled or empty based on player's permanent health status
				# This part depends on how you're tracking permanent health
			else:
				health_containers[i].visible = false

func update_currency(amount):
	coin_count.text = str(amount)

func set_ability_icon(texture):
	ability_icon.texture = texture
