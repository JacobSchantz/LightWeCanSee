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

# SIMPLE MOBILE CAMERA AND CONTROLS
# Static top-down camera position for reliability
var mobile_settings = {
	"camera_height": 8.0,     # Height above player
	"camera_distance": 4.0,   # Distance behind player
	"camera_tilt": 45.0,      # Angle in degrees (45 = halfway between horizontal and top-down)
	"move_speed": 5.0,        # Player movement speed
	"rotate_speed": 3.0,      # How fast player rotates to face movement direction
	"joystick_deadzone": 0.1  # Ignore very small joystick movements
}

@onready var pivot = $CameraPivot
@onready var camera = $CameraPivot/Camera3D
@onready var interaction_ray = $InteractionRay

# Box extension variables
var target_box = null

# Mobile control variables
var mobile_controls = null
var last_touch_pos = Vector2.ZERO
var touch_camera_rotation = false

# Video interaction tracking
var near_video_wall = false

func _ready():
	# Add player to the player group for interactions
	add_to_group("player")
	
	# Store initial spawn position
	spawn_position = global_position
	
	# Platform-specific setup
	# if OS.has_feature("pc"):
	# 	# Desktop controls setup
	# 	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	# 	# Make sure mobile controls are hidden on desktop
	# 	if get_tree().get_root().has_node("MobileControls"):
	# 		get_tree().get_root().get_node("MobileControls").hide()
	# else:
		# Mobile controls setup
		# Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		
		# Set up the new fixed camera system
	setup_mobile_camera()
	
	# Find mobile controls using multiple possible paths
	mobile_controls = get_node_or_null("/root/MobileControls")
	if mobile_controls == null:
		# Try alternative paths
		mobile_controls = get_node_or_null("/root/Main/MobileControls")
		if mobile_controls == null:
			mobile_controls = get_node_or_null("/root/GameScene/MobileControls")
	
	# Setup mobile controls if found
	if mobile_controls != null:
		mobile_controls.show() # Make sure mobile controls are visible
		mobile_controls.extend_box_pressed.connect(func(): toggle_box_size())
		mobile_controls.shrink_box_pressed.connect(func(): toggle_box_size())
		mobile_controls.jump_pressed.connect(func(): velocity.y = JUMP_VELOCITY if is_on_floor() else 0.0)
		print("Mobile controls connected successfully!")
	else:
		print("WARNING: Mobile controls not found - movement may not work!")

# Common physics processing for all platforms
func _physics_process(delta):
	# Don't process player movement when game is paused
	if get_tree().paused:
		return
		
	# Add the gravity
	if not is_on_floor():
		velocity.y -= ProjectSettings.get_setting("physics/3d/default_gravity") * delta

	# Handle Jump.
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# # Get the input direction and handle the movement/deceleration.
	# if OS.has_feature("pc"):
	# 	process_desktop_movement(delta)
	# else:
		# Mobile-specific updates - SIMPLIFIED
	process_mobile_movement(delta) # Fixed version
		
	# Detect if player fell off the level
	if global_position.y < FALL_THRESHOLD:
		global_position = spawn_position
		velocity = Vector3.ZERO
	
	# Check for box extension on desktop (mobile uses buttons instead)
	if OS.has_feature("pc") and Input.is_action_just_pressed("extend_box"):
		toggle_box_size()

	# Apply movement
	move_and_slide()
	
# Desktop-specific movement processing
func process_desktop_movement(delta):
	# Handle Jump - don't jump if near video wall
	if Input.is_action_just_pressed("ui_accept") and is_on_floor() and not near_video_wall:
		velocity.y = JUMP_VELOCITY
	
	# Get keyboard input
	var input_dir = Input.get_vector("ui_left", "ui_right", "ui_down", "ui_up")
	
	# Calculate and apply movement
	apply_movement_from_input(input_dir)

# EXTREMELY SIMPLE mobile movement system
func process_mobile_movement(delta):
	# Only process if we have mobile controls
	if mobile_controls == null:
		print("No mobile controls found!")
		return

	# Get joystick input - DIRECT approach
	var joy_vec = mobile_controls.get_joystick_vector()
	
	# Check if we have meaningful input (use a very small deadzone)
	if joy_vec.length() > mobile_settings.joystick_deadzone:
		# Flip Y axis so up on joystick moves character forward
		joy_vec.y = -joy_vec.y
		
		print("Joystick input: ", joy_vec) # Debug output
		
		# Convert to world space direction (camera is fixed above and behind)
		var move_dir = Vector3(joy_vec.x, 0, joy_vec.y).normalized()
		
		# Calculate speed based on joystick intensity
		var speed = mobile_settings.move_speed * joy_vec.length()
		
		# Set velocity directly
		velocity.x = move_dir.x * speed
		velocity.z = move_dir.z * speed
		
		# Visually rotate player to face movement direction
		if move_dir.length() > 0.1:
			var target_angle = atan2(-move_dir.x, -move_dir.z)
			
			# Smoothly rotate toward movement direction
			var angle_diff = target_angle - rotation.y
			
			# Normalize the angle difference
			while angle_diff > PI:
				angle_diff -= 2 * PI
			while angle_diff < -PI:
				angle_diff += 2 * PI
			
			# Apply smooth rotation
			rotation.y += angle_diff * min(1.0, delta * mobile_settings.rotate_speed)
	else:
		# No input - slow down
		velocity.x = move_toward(velocity.x, 0, mobile_settings.move_speed * delta * 5)
		velocity.z = move_toward(velocity.z, 0, mobile_settings.move_speed * delta * 5)

# REBUILT movement calculation used by both platforms
func apply_movement_from_input(input_dir):
	# Calculate movement direction relative to camera orientation
	# This makes movement relative to where the player is looking
	var forward = -transform.basis.z
	var right = transform.basis.x
	
	# Zero out the y component to keep movement horizontal
	forward.y = 0
	right.y = 0
	forward = forward.normalized()
	right = right.normalized()
	
	# Calculate the movement direction vector
	var move_direction = right * input_dir.x + forward * input_dir.y
	
	if move_direction.length() > 0.05: # More sensitive threshold
		# Get input intensity for analog control (between 0-1)
		var intensity = clamp(input_dir.length(), 0.0, 1.0)
		
		# Apply movement with analog intensity
		velocity.x = move_direction.x * SPEED * intensity
		velocity.z = move_direction.z * SPEED * intensity
		
		# Debug movement
		#print("Moving: ", velocity)
	else:
		# Slow down to a stop
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)

	move_and_slide()
	
	# Check for box extension
	if Input.is_action_just_pressed("extend_box"):
		toggle_box_size()

func _input(event):
	# Don't process input when game is paused
	if get_tree().paused:
		return
		
	# Route input to platform-specific handlers
	if OS.has_feature("pc"):
		process_desktop_input(event)
	else:
		process_mobile_input(event)

# Handle desktop-specific input events
func process_desktop_input(event):
	if event is InputEventMouseMotion:
		# Horizontal camera rotation - rotate the player
		rotation.y -= event.relative.x * mouse_sensitivity
		
		# Vertical camera rotation - rotate the camera pivot
		camera_angle -= event.relative.y * mouse_sensitivity
		camera_angle = clamp(camera_angle, deg_to_rad(min_pitch), deg_to_rad(max_pitch))
		pivot.rotation.x = camera_angle

# SUPER SIMPLE mobile input handling - basic touch controls
func process_mobile_input(event):
	# We're using a static camera for mobile, so no camera control needed
	pass # All movement is now handled directly in process_mobile_movement

# Set up a fixed camera position for mobile
func setup_mobile_camera():
	if not OS.has_feature("pc"):
		# Position the camera pivot
		pivot.position = Vector3(0, 1.5, 0) # Center at player's head level
		
		# Calculate the camera's position
		var height = mobile_settings.camera_height
		var distance = mobile_settings.camera_distance
		var angle = deg_to_rad(mobile_settings.camera_tilt)
		
		# Place camera at fixed position
		camera.position = Vector3(0, height, distance)
		
		# Tilt camera down to look at player
		camera.rotation.x = -angle
		
		# Print confirmation
		print("Mobile camera positioned at height: ", height, " distance: ", distance)

# Simple fixed update for mobile camera (call this in _ready)
# Function has been merged with the main _ready function above
	
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
