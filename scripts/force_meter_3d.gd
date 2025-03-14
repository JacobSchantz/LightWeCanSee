extends Node3D

@onready var force_bar = $ForceBar
@onready var force_value = $ForceValue

var max_force = 100.0
var min_color = Color(0.0, 0.8, 0.2)  # Green
var max_color = Color(1.0, 0.0, 0.0)  # Red
var neutral_color = Color(0.267, 0.584, 0.933)  # Blue

# Initialize the force meter
func _ready():
	# Hide the force meter initially
	visible = false
	
	# Set initial scale to zero
	force_bar.scale.x = 0.0

# Update the force meter appearance based on current force
func update_force(force_amount):
	# Ensure the force is in valid range
	var clamped_force = clamp(force_amount, 0.0, max_force)
	
	# Calculate the percentage of maximum force
	var force_percent = clamped_force / max_force
	
	# Update the bar length based on force
	force_bar.scale.x = force_percent
	
	# Center the bar based on new scale
	force_bar.position.x = force_percent * 0.5
	
	# Update the text
	force_value.text = "%.1f N" % clamped_force
	
	# Change color based on force intensity
	if clamped_force > 0:
		var material = force_bar.get_surface_override_material(0).duplicate()
		var color = min_color.lerp(max_color, force_percent)
		material.albedo_color = color
		material.emission = color
		force_bar.set_surface_override_material(0, material)
		force_value.modulate = color
	else:
		var material = force_bar.get_surface_override_material(0).duplicate()
		material.albedo_color = neutral_color
		material.emission = neutral_color
		force_bar.set_surface_override_material(0, material)
		force_value.modulate = neutral_color

# Show the force meter
func show_meter():
	visible = true

# Hide the force meter
func hide_meter():
	visible = false
