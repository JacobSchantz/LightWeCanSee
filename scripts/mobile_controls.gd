extends CanvasLayer

@onready var joystick = $Joystick
@onready var joystick_bg = $Joystick/Background
@onready var joystick_thumb = $Joystick/Thumb
@onready var action_buttons = $ActionButtons
@onready var pause_button = $PauseButton

signal pause_pressed
signal extend_box_pressed
signal shrink_box_pressed
signal jump_pressed

# Joystick properties - based on industry standards
var joystick_active = false
var joystick_origin = Vector2()
var joy_vector = Vector2()
var joy_max_distance = 100

# Deadzone for better control
var deadzone = 0.2

# Dynamic joystick positioning
var use_dynamic_joystick = true
var joystick_default_position = Vector2()

func _ready():
	# Always show mobile controls on all platforms now
	
	# Save default joystick position for non-dynamic mode
	joystick_default_position = joystick.position
	
	# Reset joystick visual state
	joystick_thumb.position = Vector2.ZERO
	
	# Show all controls explicitly
	show()
	$ActionButtons.show()
	$Joystick.show()
	$PauseButton.show()
	
	# Make sure joystick is visible
	print("Mobile controls enabled on all platforms")
	
	# If using dynamic joystick, hide until touched
	if use_dynamic_joystick:
		joystick.visible = false
	
	# Connect button signals
	$PauseButton.pressed.connect(func(): pause_pressed.emit())
	$ActionButtons/ExtendButton.pressed.connect(func(): extend_box_pressed.emit())
	$ActionButtons/ShrinkButton.pressed.connect(func(): shrink_box_pressed.emit())
	
	# Add jump button if it exists
	if $ActionButtons/JumpButton:
		$ActionButtons/JumpButton.pressed.connect(func(): jump_pressed.emit())

func _input(event):
	# Only skip if paused - now process on all platforms
	if get_tree().paused:
		return
	
	# Handle touch input for joystick
	if event is InputEventScreenTouch:
		# Only process left half of screen for joystick
		if event.position.x < get_viewport().size.x * 0.5:
			if event.pressed:
				# Start joystick control
				joystick_active = true
				
				# Set joystick position - either dynamic or fixed
				if use_dynamic_joystick:
					# Place joystick at touch position
					joystick_origin = event.position
					joystick.position = joystick_origin
				else:
					# Use default position
					joystick_origin = joystick_default_position
				
				# Make sure joystick is visible
				joystick.visible = true
				# Reset thumb position
				joystick_thumb.position = Vector2.ZERO
			else:
				# End joystick control
				joystick_active = false
				joy_vector = Vector2.ZERO
				
				# If using dynamic joystick, hide when not in use
				if use_dynamic_joystick:
					joystick.visible = false
				else:
					# Reset thumb to center position
					joystick_thumb.position = Vector2.ZERO
				
				# Release all movement inputs
				release_all_movement()
	
	# Handle drag input for joystick movement
	elif event is InputEventScreenDrag:
		if joystick_active:
			# Calculate joystick movement vector
			var joy_delta = event.position - joystick_origin
			
			# Limit the drag distance to max joystick range
			var limited_delta = joy_delta.limit_length(joy_max_distance)
			
			# Update thumb position visually
			joystick_thumb.position = limited_delta
			
			# Calculate the normalized vector (0-1 range)
			joy_vector = joy_delta / joy_max_distance
			
			# Apply deadzone - helps with precision
			if joy_vector.length() < deadzone:
				joy_vector = Vector2.ZERO
			else:
				# Adjust for deadzone and normalize
				joy_vector = joy_vector.normalized() * ((joy_vector.length() - deadzone) / (1 - deadzone))

func get_joystick_vector():
	return joy_vector

# Helper function to release all movement inputs
func release_all_movement():
	Input.action_release("ui_up")
	Input.action_release("ui_down")
	Input.action_release("ui_left")
	Input.action_release("ui_right")

# Get a vector for direct use without going through input actions
func get_raw_joystick_vector():
	return joy_vector

# COMPLETELY REDESIGNED joystick input processing
func _process(_delta):
	# Now process controls on all platforms - only pause stops processing
	if get_tree().paused:
		return
	
	# Always release all standard inputs first to prevent stuck controls
	release_all_movement()
	
	# Direct joystick vector is now our preferred approach
	# The get_joystick_vector() function will return this directly to the player
	# and the player script will use it directly rather than through Input actions
	
	# However, we'll keep the Input actions as a fallback for compatibility
	if joystick_active and joy_vector.length() > 0.05: # More sensitive threshold
		# Using analog thresholds for smoother gradual movement
		var threshold = 0.1 # Lower threshold for better responsiveness
		
		# Map joystick to Input actions as a compatibility measure
		if joy_vector.y < -threshold:
			Input.action_press("ui_up", abs(joy_vector.y)) # Pass analog value
		if joy_vector.y > threshold:
			Input.action_press("ui_down", abs(joy_vector.y))
		if joy_vector.x < -threshold:
			Input.action_press("ui_left", abs(joy_vector.x))
		if joy_vector.x > threshold:
			Input.action_press("ui_right", abs(joy_vector.x))
