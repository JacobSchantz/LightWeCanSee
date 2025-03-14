extends StaticBody3D

signal door_opened
signal door_closed

@export var is_locked: bool = true
@export var animation_duration: float = 1.0

@onready var door_mesh = $DoorMesh
@onready var collision_shape = $CollisionShape3D
@onready var lock_indicator = $LockIndicator
@onready var door_sound = $DoorSound

# Animation properties
var initial_position = Vector3.ZERO
var open_position = Vector3(0, 4, 0)  # Door slides up when opened
var is_open = false
var tween = null

func _ready():
	initial_position = door_mesh.position
	update_lock_indicator()

func lock():
	is_locked = true
	close_door()
	update_lock_indicator()

func unlock():
	is_locked = false
	update_lock_indicator()
	open_door()

func open_door():
	if is_locked or is_open:
		return

	# Create a new tween for animation
	tween = create_tween()
	tween.tween_property(door_mesh, "position", initial_position + open_position, animation_duration)
	
	# Play door sound if available
	if door_sound:
		door_sound.play()
		
	# Wait for animation to complete
	await tween.finished
	
	# Disable collision when door is open
	collision_shape.disabled = true
	is_open = true
	
	emit_signal("door_opened")

func close_door():
	if is_open == false:
		return
		
	# Enable collision when door is closing
	collision_shape.disabled = false
	
	# Create a new tween for animation
	tween = create_tween()
	tween.tween_property(door_mesh, "position", initial_position, animation_duration)
	
	# Play door sound if available
	if door_sound:
		door_sound.play()
		
	# Wait for animation to complete
	await tween.finished
	
	is_open = false
	emit_signal("door_closed")

func update_lock_indicator():
	if lock_indicator and lock_indicator.has_node("Sprite3D"):
		var indicator = lock_indicator.get_node("Sprite3D")
		var material = StandardMaterial3D.new()
		material.albedo_color = Color.RED if is_locked else Color.GREEN
		material.emission_enabled = true
		material.emission = Color.RED if is_locked else Color.GREEN
		material.emission_energy_multiplier = 1.5
		indicator.set_surface_override_material(0, material)
