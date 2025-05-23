extends CanvasLayer

@onready var joystick = $Joystick
@onready var action_buttons = $ActionButtons
@onready var pause_button = $PauseButton

signal pause_pressed
signal extend_box_pressed
signal shrink_box_pressed

var joystick_active = false
var joystick_origin = Vector2()
var joy_vector = Vector2()
var joy_max_distance = 100

func _ready():
	# Completely hide all mobile controls on desktop platforms
	if OS.has_feature("pc"):
		# Make everything invisible
		hide()
		# Also hide all children to be extra sure
		$ActionButtons.hide()
		$Joystick.hide()
		$PauseButton.hide()
	
	$PauseButton.pressed.connect(func(): pause_pressed.emit())
	$ActionButtons/ExtendButton.pressed.connect(func(): extend_box_pressed.emit())
	$ActionButtons/ShrinkButton.pressed.connect(func(): shrink_box_pressed.emit())

func _input(event):
	if OS.has_feature("pc"):
		return
		
	if event is InputEventScreenTouch:
		if event.position.x < get_viewport().size.x / 2 and event.position.y > get_viewport().size.y / 2:
			if event.pressed:
				joystick_active = true
				joystick_origin = event.position
				joystick.position = event.position
				joystick.visible = true
			else:
				joystick_active = false
				joystick.visible = false
				joy_vector = Vector2.ZERO
				# Release all movement keys when touch ends
				Input.action_release("ui_up")
				Input.action_release("ui_down")
				Input.action_release("ui_left")
				Input.action_release("ui_right")
				
	elif event is InputEventScreenDrag and joystick_active:
		var joy_delta = event.position - joystick_origin
		joy_vector = joy_delta.normalized() * min(joy_delta.length(), joy_max_distance) / joy_max_distance
		joystick.get_node("Thumb").position = joy_delta.limit_length(joy_max_distance)

func get_joystick_vector():
	return joy_vector

func _process(_delta):
	# Only process mobile controls on mobile platforms
	if OS.has_feature("pc"):
		return
	
	if joystick_active:
		# Simulate keyboard input based on joystick position
		Input.action_press("ui_up") if joy_vector.y < -0.3 else Input.action_release("ui_up")
		Input.action_press("ui_down") if joy_vector.y > 0.3 else Input.action_release("ui_down")
		Input.action_press("ui_left") if joy_vector.x < -0.3 else Input.action_release("ui_left")
		Input.action_press("ui_right") if joy_vector.x > 0.3 else Input.action_release("ui_right")
	else:
		# Ensure all movement keys are released when joystick is not active
		Input.action_release("ui_up")
		Input.action_release("ui_down")
		Input.action_release("ui_left")
		Input.action_release("ui_right")
