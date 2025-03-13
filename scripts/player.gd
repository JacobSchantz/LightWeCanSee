extends CharacterBody3D

const SPEED = 5.0
const JUMP_VELOCITY = 4.5
const ROTATION_SPEED = 5.0

# Camera control
var mouse_sensitivity = 0.002
var camera_angle = 0
var min_pitch = -50.0
var max_pitch = 70.0

@onready var pivot = $CameraPivot
@onready var camera = $CameraPivot/Camera3D
@onready var interaction_ray = $InteractionRay

# Get the gravity from the project settings to be synced with RigidBody nodes
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

func _ready():
	# Add player to the player group for interactions
	add_to_group("player")
	
	# Capture mouse for camera control
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _physics_process(delta):
	# Add the gravity
	if not is_on_floor():
		velocity.y -= gravity * delta

	# Handle Jump
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Get the input direction and handle the movement/deceleration
	var input_dir = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	if direction:
		# Gradually rotate the player to face the movement direction
		var target_rotation = atan2(-direction.x, -direction.z)
		var current_rotation = rotation.y
		var rotation_diff = wrapf(target_rotation - current_rotation, -PI, PI)
		rotation.y += rotation_diff * ROTATION_SPEED * delta
		
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)

	move_and_slide()
	
	# Check for interaction
	if Input.is_action_just_pressed("interact"):
		if interaction_ray.is_colliding():
			var collider = interaction_ray.get_collider()
			if collider.has_method("interact"):
				collider.interact(self)

func _input(event):
	if event is InputEventMouseMotion:
		# Horizontal camera rotation - rotate the player
		rotation.y -= event.relative.x * mouse_sensitivity
		
		# Vertical camera rotation - rotate the camera pivot
		camera_angle -= event.relative.y * mouse_sensitivity
		camera_angle = clamp(camera_angle, deg_to_rad(min_pitch), deg_to_rad(max_pitch))
		pivot.rotation.x = camera_angle
		
	if event.is_action_pressed("ui_cancel"):
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		else:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
