extends CharacterBody3D

const SPEED = 5.0
const JUMP_VELOCITY = 4.5
const ROTATION_SPEED = 5.0

# Fall detection
const FALL_THRESHOLD = -30.0  # Y position below which the player is considered to have fallen off
var spawn_position = Vector3.ZERO  # Store initial spawn position

# Camera control
var mouse_sensitivity = 0.002
var camera_angle = 0
var min_pitch = -50.0
var max_pitch = 70.0

@onready var pivot = $CameraPivot
@onready var camera = $CameraPivot/Camera3D
@onready var interaction_ray = $InteractionRay

# Box extension variables
var target_box = null

func _ready():
	# Add player to the player group for interactions
	add_to_group("player")
	
	# Capture mouse for camera control
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	
	# Store initial spawn position
	spawn_position = global_position

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

	# Get the input direction
	# Note: Reversing up/down to fix the flipped forward/backward movement
	var input_dir = Input.get_vector("ui_left", "ui_right", "ui_down", "ui_up")
	
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
	if event is InputEventMouseMotion:
		# Only process mouse movement when game is not paused
		if not get_tree().paused:
			# Horizontal camera rotation - rotate the player
			rotation.y -= event.relative.x * mouse_sensitivity
			
			# Vertical camera rotation - rotate the camera pivot
			camera_angle -= event.relative.y * mouse_sensitivity
			camera_angle = clamp(camera_angle, deg_to_rad(min_pitch), deg_to_rad(max_pitch))
			pivot.rotation.x = camera_angle
	
	# NOTE: Escape key handling is now done in the main script to properly show the pause menu

# Simple function to toggle box size
func toggle_box_size():
	# Find the box
	var boxes = get_tree().get_nodes_in_group("extendable_box")
	if boxes.size() > 0:
		target_box = boxes[0]  # Just take the first box for simplicity
		
		# Call the toggle_size method on the box
		if target_box.has_method("toggle_size"):
			target_box.toggle_size()

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
