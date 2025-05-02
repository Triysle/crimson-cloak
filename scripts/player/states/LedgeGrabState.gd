extends State

var ledge_position = Vector2.ZERO  # Position of the ledge
var player_offset = Vector2(0, -32)  # Offset to position player's hands at the ledge
var climb_up_requested = false  # Flag to track if climbing was requested
var using_stamina = false  # Whether ledge hanging uses stamina
var stamina_drain_rate = 0.5  # How much stamina to drain per second if enabled

func enter():
	player.animation_player.play("ledgegrab")
	
	# Stop all movement
	player.velocity = Vector2.ZERO
	
	# Disable gravity while hanging on ledge
	player.gravity_enabled = false
	
	# Position player precisely at the ledge
	player.global_position = ledge_position + player_offset

func exit():
	# Re-enable gravity
	player.gravity_enabled = true
	
	# Reset flags
	climb_up_requested = false

func physics_update(delta):
	# Skip input processing if player can't be controlled
	if not player.can_control:
		return
	
	# Stay in place
	player.velocity = Vector2.ZERO
	
	# Drain stamina if enabled
	if using_stamina and player.has_method("drain_stamina"):
		player.drain_stamina(stamina_drain_rate * delta)
		
		# Fall if out of stamina
		if player.stamina <= 0:
			state_machine.transition_to("fall")
			return
	
	# Check for climb up input (up + jump)
	if Input.is_action_pressed("move_up") and Input.is_action_just_pressed("jump"):
		climb_up_requested = true
		player.animation_player.play("ledgegrabup")
		
		# Connect to animation finished signal if not already connected
		if not player.animation_player.animation_finished.is_connected(_on_ledge_climb_finished):
			player.animation_player.animation_finished.connect(_on_ledge_climb_finished)
		return
	
	# Check for drop down input (down + jump)
	if Input.is_action_pressed("move_down") and Input.is_action_just_pressed("jump"):
		state_machine.transition_to("fall")
		return
		
	# Grab attack option (press attack while on ledge)
	if Input.is_action_just_pressed("attack"):
		state_machine.transition_to("attack")
		return
	
	# Apply movement (even though velocity is zero, to maintain proper state)
	player.move_and_slide()

func _on_ledge_climb_finished(anim_name):
	if anim_name == "ledgegrabup" and climb_up_requested:
		# Disconnect the signal to avoid multiple connections
		if player.animation_player.animation_finished.is_connected(_on_ledge_climb_finished):
			player.animation_player.animation_finished.disconnect(_on_ledge_climb_finished)
		
		# Move player to the top of the ledge
		player.global_position.y = ledge_position.y - 16  # Adjust based on player's height
		
		# Transition to idle state
		state_machine.transition_to("idle")

# Set the ledge position
func set_ledge_position(pos: Vector2):
	ledge_position = pos
