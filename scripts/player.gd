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

# Force interaction
const FORCE_MIN = 0.0
const FORCE_MAX = 100.0
const FORCE_INCREMENT = 5.0
var current_force = 0.0
var current_pushable_object = null
var is_applying_force = false

@onready var pivot = $CameraPivot
@onready var camera = $CameraPivot/Camera3D
@onready var interaction_ray = $InteractionRay
@onready var force_indicator = $UI/ForceIndicator

# Get the gravity from the project settings to be synced with RigidBody nodes
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

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
		velocity.y -= gravity * delta

	# Handle Jump
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY
		
	# Handle force application
	if is_applying_force:
		# Increase force when up arrow is pressed
		if Input.is_action_just_pressed("ui_up"):
			current_force = min(current_force + FORCE_INCREMENT, FORCE_MAX)
			update_push_object()
			
		# Decrease force when down arrow is pressed
		elif Input.is_action_just_pressed("ui_down"):
			current_force = max(current_force - FORCE_INCREMENT, FORCE_MIN)
			update_push_object()
			
		# Apply the force when space is pressed
		if Input.is_action_just_pressed("ui_select"):
			apply_force()
			
		# Cancel force application
		if Input.is_action_just_pressed("ui_cancel") or not is_interacting_with_pushable():
			end_force_interaction()

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
	
	# Check for interaction
	if Input.is_action_just_pressed("interact"):
		if interaction_ray.is_colliding():
			var collider = interaction_ray.get_collider()
			if collider.has_method("interact"):
				# If it's a pushable object, start force interaction
				if collider is RigidBody3D and collider.has_method("start_push"):
					start_force_interaction(collider)
				else:
					collider.interact()

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

# ---------- Force Interaction Methods ----------

# Start applying force to an object
func start_force_interaction(object):
	if object and object.has_method("start_push"):
		current_pushable_object = object
		is_applying_force = true
		current_force = FORCE_MIN
		
		# Get direction from player to object for pushing
		var push_direction = -transform.basis.z  # Forward direction
		object.start_push(push_direction)
		object.update_force(current_force)
		
		# Show force indicator with object mass
		if force_indicator:
			var object_name = "Box"
			var mass = 10.0
			
			# Get object name and mass if available
			if object.has_method("get_object_name"):
				object_name = object.get_object_name()
			if object.has_property("mass"):
				mass = object.mass
			elif object.has_property("mass_kg"):
				mass = object.mass_kg
			
			# Format object info with mass
			var object_info = object_name + " (" + str(mass) + " kg)"
			force_indicator.show_force(current_force, object_info)
			force_indicator.visible = true

# Update the force being applied to the object
func update_push_object():
	if current_pushable_object and is_applying_force:
		current_pushable_object.update_force(current_force)
		
		# Update force indicator display
		if force_indicator and force_indicator.visible:
			var object_name = "Box"
			var mass = 10.0
			
			# Get object name and mass if available
			if current_pushable_object.has_method("get_object_name"):
				object_name = current_pushable_object.get_object_name()
			if current_pushable_object.has_property("mass"):
				mass = current_pushable_object.mass
			elif current_pushable_object.has_property("mass_kg"):
				mass = current_pushable_object.mass_kg
			
			# Format object info with mass
			var object_info = object_name + " (" + str(mass) + " kg)"
			force_indicator.show_force(current_force, object_info)

# Actually apply the accumulated force
func apply_force():
	if current_pushable_object and is_applying_force:
		# The force is already being applied in the physics process via update_force
		# This method can be expanded if you want to apply an additional impulse
		pass

# End the force interaction
func end_force_interaction():
	if current_pushable_object and current_pushable_object.has_method("end_push"):
		current_pushable_object.end_push()
	
	current_pushable_object = null
	is_applying_force = false
	current_force = FORCE_MIN
	
	# Hide the force indicator
	if force_indicator:
		force_indicator.hide_force()
		force_indicator.visible = false

# Check if still interacting with a pushable object
func is_interacting_with_pushable():
	if not current_pushable_object:
		return false
		
	# Check if still pointing at the object
	if interaction_ray.is_colliding():
		var collider = interaction_ray.get_collider()
		return collider == current_pushable_object
		
	return false
