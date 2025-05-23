extends CharacterBody3D

const SPEED = 5.0
const JUMP_VELOCITY = 6.5  # Increased from 4.5 to allow jumping onto boxes
const ROTATION_SPEED = 5.0

# Fall detection
const FALL_THRESHOLD = -30.0  # Y position below which the player is considered to have fallen off
var spawn_position = Vector3.ZERO  # Store initial spawn position

# Camera control
var mouse_sensitivity = 0.002
var camera_angle = 0
var min_pitch = -50.0  # Default min pitch for desktop
var max_pitch = 70.0
var mobile_min_pitch = -5.0  # Restricted pitch for mobile to prevent looking below floor
var touch_rotation_speed = 0.02  # Reduced sensitivity for mobile touch rotation

@onready var pivot = $CameraPivot
@onready var camera = $CameraPivot/Camera3D
@onready var interaction_ray = $InteractionRay

# Box extension variables
var target_box = null

# Mobile control variables
var mobile_controls = null
var last_touch_pos = Vector2.ZERO
var touch_camera_rotation = false

func _ready():
	# Add player to the player group for interactions
	add_to_group("player")
	
	# Store initial spawn position
	spawn_position = global_position
	
	# Platform-specific setup
	if OS.has_feature("pc"):
		# Desktop controls setup
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		# Make sure mobile controls are hidden on desktop
		if get_tree().get_root().has_node("MobileControls"):
			get_tree().get_root().get_node("MobileControls").hide()
	else:
		# Mobile controls setup
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		# Initialize camera with a safer angle on mobile
		camera_angle = deg_to_rad(10.0)  # Start with a slight downward angle
		pivot.rotation.x = camera_angle
		
		# Setup mobile controls if available
		if get_tree().get_root().has_node("MobileControls"):
			mobile_controls = get_tree().get_root().get_node("MobileControls")
			mobile_controls.show() # Make sure mobile controls are visible
			mobile_controls.extend_box_pressed.connect(func(): toggle_box_size())
			mobile_controls.shrink_box_pressed.connect(func(): toggle_box_size())

func _physics_process(delta):
	# Don't process player movement when game is paused
	if get_tree().paused:
		return
		
	# Check if player has fallen off the world
	if global_position.y < FALL_THRESHOLD:
		restart_level()
		return
	
	# Add the gravity
	if not is_on_floor():
		velocity.y -= ProjectSettings.get_setting("physics/3d/default_gravity") * delta

	# Handle Jump
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Get the input direction based on platform
	var input_dir = Vector2.ZERO
	
	# Platform-specific input handling
	if OS.has_feature("pc"):
		# Desktop controls - use keyboard
		# Note: Reversing up/down to fix the flipped forward/backward movement
		input_dir = Input.get_vector("ui_left", "ui_right", "ui_down", "ui_up")
	else:
		# Mobile controls - use joystick if available
		if mobile_controls != null:
			# Get joystick vector and reverse Y for consistent forward/backward
			var joy_vec = mobile_controls.get_joystick_vector()
			# Flip the Y axis to match our control scheme
			input_dir = Vector2(joy_vec.x, -joy_vec.y)
	
	# Calculate movement direction relative to camera orientation
	# This makes movement relative to where the player is looking
	var forward = -transform.basis.z
	var right = transform.basis.x
	
	# Zero out the y component and normalize
	forward.y = 0
	right.y = 0
	forward = forward.normalized()
	right = right.normalized()
	
	# Calculate the movement direction vector
	var move_direction = right * input_dir.x + forward * input_dir.y
	
	if move_direction.length() > 0.1:
		# Apply movement without changing rotation
		velocity.x = move_direction.x * SPEED
		velocity.z = move_direction.z * SPEED
	else:
		# Decelerate smoothly when no input
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)

	move_and_slide()
	
	# Check for box extension
	if Input.is_action_just_pressed("extend_box"):
		toggle_box_size()

func _input(event):
	if get_tree().paused:
		return
		
	if OS.has_feature("pc"):
		if event is InputEventMouseMotion:
			# Only process mouse movement when game is not paused
			if not get_tree().paused:
				# Horizontal camera rotation - rotate the player
				rotation.y -= event.relative.x * mouse_sensitivity
				
				# Vertical camera rotation - rotate the camera pivot
				camera_angle -= event.relative.y * mouse_sensitivity
				camera_angle = clamp(camera_angle, deg_to_rad(min_pitch), deg_to_rad(max_pitch))
				pivot.rotation.x = camera_angle
	else:
		# Mobile camera rotation via touch
		if event is InputEventScreenTouch:
			if event.position.x > get_viewport().size.x / 2:
				if event.pressed:
					touch_camera_rotation = true
					last_touch_pos = event.position
				else:
					touch_camera_rotation = false
					
		elif event is InputEventScreenDrag and touch_camera_rotation:
			var delta = event.position - last_touch_pos
			
			# Horizontal camera rotation - rotate the player
			rotation.y -= delta.x * touch_rotation_speed
			
			# Vertical camera rotation - rotate the camera pivot
			camera_angle -= delta.y * touch_rotation_speed
			# Use the mobile-specific min_pitch to prevent looking below the floor
			camera_angle = clamp(camera_angle, deg_to_rad(mobile_min_pitch), deg_to_rad(max_pitch))
			pivot.rotation.x = camera_angle
			
			last_touch_pos = event.position
	
	# NOTE: Escape key handling is now done in the main script to properly show the pause menu

# Enhanced function to toggle box size
func toggle_box_size():
	# Try to find the box through multiple methods
	
	# Method 1: Check if we already have a reference
	if target_box == null or !is_instance_valid(target_box):
		# Method 2: Try to find by group
		var boxes = get_tree().get_nodes_in_group("extendable_box")
		if boxes.size() > 0:
			target_box = boxes[0]
		
		# Method 3: Try to find by node name
		if target_box == null:
			if get_tree().get_root().has_node("InteractiveBox"):
				target_box = get_tree().get_root().get_node("InteractiveBox")
			elif get_tree().get_current_scene().has_node("InteractiveBox"):
				target_box = get_tree().get_current_scene().get_node("InteractiveBox")

	# If we found the box, call its toggle_size method
	if target_box != null and target_box.has_method("toggle_size"):
		print("Toggling box size from mobile")
		target_box.toggle_size()
	else:
		print("Could not find interactive box for size toggle")
		# Print scene tree for debugging
		print_tree()
			
# Function for interaction
func interact():
	if interaction_ray.is_colliding():
		var collider = interaction_ray.get_collider()
		if collider.has_method("interact"):
			collider.interact()

# Handles restarting the level when the player falls off the world
func restart_level():
	# Display a brief message (optional)
	print("Player fell out of bounds - restarting level")
	
	# Option 1: Simply respawn at the initial position
	global_position = spawn_position
	velocity = Vector3.ZERO
	
	# Option 2: If you want a proper level restart, uncomment this instead
	# get_tree().reload_current_scene()
	
	# Play respawn sound effect if available
	if has_node("RespawnSound"):
		get_node("RespawnSound").play()
	
	# Optional: Brief screen effect to indicate respawn
	if has_node("/root/LevelManager"):
		var level_manager = get_node("/root/LevelManager")
		if level_manager.has_method("play_respawn_effect"):
			level_manager.play_respawn_effect()
