extends RigidBody3D

signal force_applied(amount, object_name)
signal force_released

@export var object_name = "Box"
@export var mass_kg = 10.0
@export var force_multiplier = 1.0
@export var max_applied_force = 100.0
@export var highlight_color: Color = Color(1.0, 0.8, 0.4, 1.0)
@export var surface_friction = 0.3

var original_materials = []
var is_player_near = false
var applied_force = 0.0
var is_being_pushed = false
var push_direction = Vector3.ZERO
var force_meter = null
var physics_calculator = null

# Reference to components
@onready var mesh_instance = $MeshInstance3D
@onready var box_label = $BoxLabel

func _ready():
	# Store original materials for highlighting later
	if mesh_instance:
		if mesh_instance.get_surface_override_material_count() > 0:
			for i in range(mesh_instance.get_surface_override_material_count()):
				original_materials.append(mesh_instance.get_surface_override_material(i))
		elif mesh_instance.mesh and mesh_instance.mesh.get_material():
			original_materials.append(mesh_instance.mesh.get_material())
	
	# Initialize the C++ physics calculator - using try/catch to handle if extension isn't available
	try:
		if ClassDB.class_exists("PhysicsCalculator"):
			physics_calculator = PhysicsCalculator.new()
			print("C++ Physics Calculator initialized successfully")
	except:
		print("PhysicsCalculator extension not available, using GDScript implementation")
	
	# Set the mass
	mass = mass_kg
	
	# Initialize the box label
	if box_label:
		box_label.text = "%s\n%d kg" % [object_name, mass_kg]
		box_label.modulate = Color(1, 1, 1, 1)
		
	# Create and add the 3D force meter
	var force_meter_scene = load("res://scenes/force_meter_3d.tscn")
	force_meter = force_meter_scene.instantiate()
	# Position the force meter slightly to the side of the box
	force_meter.transform.origin = Vector3(0, 1.5, 0)
	add_child(force_meter)
	force_meter.hide_meter()

func _physics_process(delta):
	if is_being_pushed and applied_force > 0:
		# Use the C++ physics calculator if available
		if physics_calculator:
			try:
				# Calculate force using C++ for better performance
				var calculated_force = physics_calculator.calculate_complex_force(
					push_direction, 
					applied_force, 
					mass_kg, 
					surface_friction
				)
				apply_central_force(calculated_force)
			except:
				# Fallback to GDScript implementation if method call fails
				print("C++ method call failed, using GDScript implementation")
				apply_central_force(push_direction * applied_force)
		else:
			# Fallback to GDScript implementation
			apply_central_force(push_direction * applied_force)
		
		# Visual feedback based on force
		var movement_feedback = min(applied_force / max_applied_force, 1.0)
		if mesh_instance and mesh_instance.get_surface_override_material_count() > 0:
			var material = mesh_instance.get_surface_override_material(0).duplicate()
			material.albedo_color = material.albedo_color.lerp(highlight_color, movement_feedback * 0.5)
			mesh_instance.set_surface_override_material(0, material)
		
		# Update the force label with improved information
		if box_label:
			var calc_type = "C++" if (physics_calculator != null) else "GDScript"
			box_label.text = "%s\n%d kg\nForce: %.1f N\nUsing: %s" % [object_name, mass_kg, applied_force, calc_type]
			var force_color = Color.GREEN.lerp(Color.RED, movement_feedback)
			box_label.modulate = force_color
		
		# Update the 3D force meter
		if force_meter:
			force_meter.show_meter()
			force_meter.update_force(applied_force)
			
			# Orient force meter based on push direction
			var look_at_pos = global_transform.origin + push_direction * 2.0
			force_meter.look_at(look_at_pos, Vector3.UP)

# Called when player starts interaction
func start_push(direction):
	is_being_pushed = true
	push_direction = direction.normalized()
	
func update_force(amount):
	applied_force = clamp(amount * force_multiplier, 0, max_applied_force)
	emit_signal("force_applied", applied_force, object_name)

# Called when player ends interaction
func end_push():
	is_being_pushed = false
	applied_force = 0
	push_direction = Vector3.ZERO
	emit_signal("force_released")
	
	# Reset material
	if mesh_instance and original_materials.size() > 0:
		for i in range(original_materials.size()):
			if i < mesh_instance.get_surface_override_material_count():
				mesh_instance.set_surface_override_material(i, original_materials[i])
	
	# Reset the label
	if box_label:
		box_label.text = "%s\n%d kg" % [object_name, mass_kg]
		box_label.modulate = Color(1, 1, 1, 1)
	
	# Hide the force meter
	if force_meter:
		force_meter.hide_meter()

# Interact with this object
func interact():
	print("Interacting with ", object_name)
	# This is called when player initially interacts with object
	return true

# Player entered range of object
func player_entered(player):
	is_player_near = true
	highlight(true)

# Player exited range of object
func player_exited(player):
	is_player_near = false
	highlight(false)
	end_push()

# Toggle highlight effect
func highlight(enable):
	if enable:
		if mesh_instance and mesh_instance.get_surface_override_material_count() > 0:
			var highlight_material = mesh_instance.get_surface_override_material(0).duplicate()
			highlight_material.albedo_color = highlight_material.albedo_color.lerp(highlight_color, 0.3)
			mesh_instance.set_surface_override_material(0, highlight_material)
	else:
		# Reset to original material
		if mesh_instance and original_materials.size() > 0:
			for i in range(original_materials.size()):
				if i < mesh_instance.get_surface_override_material_count():
					mesh_instance.set_surface_override_material(i, original_materials[i])

# Get the name of this object (for UI display)
func get_object_name():
	return object_name
