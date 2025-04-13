extends CanvasLayer

@onready var health_bar = $MarginContainer/HBoxContainer/VBoxContainer/HealthBar
@onready var coin_count = $MarginContainer/HBoxContainer/VBoxContainer3/CurrencyDisplay/CoinCount
@onready var ability_icon = $MarginContainer/HBoxContainer/VBoxContainer2/AbilityIcon

# References to individual health segments
var health_segments = []

func _ready():
	# Get references to all health segments
	for child in health_bar.get_children():
		if child.name.begins_with("HealthSegment"):
			health_segments.append(child)

func update_health(current_health, max_health):
	# Hide all segments first
	for segment in health_segments:
		segment.visible = false
	
	# Show the correct number of segments based on max_health
	for i in range(min(max_health, health_segments.size())):
		health_segments[i].visible = true
		
		# Color the segment based on current health
		if i < current_health:
			health_segments[i].color = Color(0.8, 0, 0)  # Red for filled health
		else:
			health_segments[i].color = Color(0.3, 0.3, 0.3)  # Gray for empty health

func update_currency(amount):
	coin_count.text = str(amount)

func set_ability_icon(texture):
	ability_icon.texture = texture
