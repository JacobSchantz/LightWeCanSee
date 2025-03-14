extends "res://scripts/base_level.gd"

# Physics puzzle properties
var box_mass = 10.0  # kg
var required_acceleration = 2.0  # m/s²
var correct_force = 20.0  # N (F = m * a = 10 * 2 = 20)

# Force application properties
var current_force = 0.0
var force_increment = 5.0
var is_player_near_box = false
var force_applied = false

# Visual feedback
@onready var box = $PhysicsObjects/Box
@onready var force_indicator = $PhysicsObjects/ForceIndicator
@onready var mass_label = $PhysicsObjects/MassLabel

# Sound effects
@onready var success_sound = $Sounds/SuccessSound
@onready var push_sound = $Sounds/PushSound
@onready var hint_sound = $Sounds/HintSound

func _ready():
	super._ready()
	
	# Set level properties
	level_name = "Force Application"
	level_description = "Find the right amount of force to move the box"
	
	# Setup interaction area
	if box.has_node("InteractArea"):
		var interact_area = box.get_node("InteractArea")
		interact_area.connect("body_entered", Callable(self, "_on_box_interaction_area_entered"))
		interact_area.connect("body_exited", Callable(self, "_on_box_interaction_area_exited"))
	
	# Setup visual cues
	if mass_label:
		mass_label.text = "Mass: " + str(box_mass) + " kg"
	
	# Initialize force indicator (visual representation of applied force)
	update_force_indicator()

func _process(delta):
	if is_player_near_box and not force_applied:
		# Show visual hints that this object can be interacted with
		if Input.is_action_just_pressed("interact"):
			# Player is holding the interaction button
			push_sound.play()
			
		# Increase force when pressing up arrow
		if Input.is_action_just_pressed("ui_up"):
			current_force += force_increment
			update_force_indicator()
			
		# Decrease force when pressing down arrow
		if Input.is_action_just_pressed("ui_down"):
			current_force = max(0, current_force - force_increment)
			update_force_indicator()
			
		# Apply the current force when pressing the action button
		if Input.is_action_just_pressed("ui_accept"):
			apply_force()

func _on_box_interaction_area_entered(body):
	if body.is_in_group("player"):
		is_player_near_box = true
		# Show a subtle hint
		if force_indicator:
			force_indicator.visible = true
		if hint_sound:
			hint_sound.play()

func _on_box_interaction_area_exited(body):
	if body.is_in_group("player"):
		is_player_near_box = false
		if force_indicator:
			force_indicator.visible = false

func update_force_indicator():
	if force_indicator:
		# Update the size/color of the force indicator based on current_force
		var scale_factor = current_force / 50.0  # Normalize to a reasonable scale
		force_indicator.scale = Vector3(1, scale_factor, 1)
		
		# Change color based on how close to correct force
		var proximity = abs(current_force - correct_force) / correct_force
		if proximity < 0.1:  # Within 10% of correct
			force_indicator.modulate = Color.GREEN
		elif proximity < 0.3:  # Within 30% of correct
			force_indicator.modulate = Color.YELLOW
		else:
			force_indicator.modulate = Color.RED
		
		# Show the current force value
		if force_indicator.has_node("ForceValue"):
			force_indicator.get_node("ForceValue").text = str(current_force) + " N"

func apply_force():
	force_applied = true
	
	# Check if force is close enough to correct (allows for some margin of error)
	var force_error = abs(current_force - correct_force) / correct_force
	
	if force_error <= 0.2:  # Within 20% of correct answer
		# Success! Box moves correctly
		if success_sound:
			success_sound.play()
		
		# Show success visual effect
		var success_effect = create_visual_effect("res://effects/success_particles.tscn", box.global_position)
		
		# Move the box using physics or animation
		var tween = create_tween()
		tween.tween_property(box, "position", box.position + Vector3(0, 0, -5), 1.5)
		await tween.finished
		
		# Complete the level
		complete_level()
	elif current_force < correct_force:
		# Too little force - box barely moves or shakes
		show_box_reaction_too_light()
		reset_interaction()
	else:
		# Too much force - box moves too fast or in wrong direction
		show_box_reaction_too_heavy()
		reset_interaction()

func show_box_reaction_too_light():
	# Create subtle shake animation
	var tween = create_tween()
	tween.tween_property(box, "position", box.position + Vector3(0.2, 0, 0), 0.1)
	tween.tween_property(box, "position", box.position - Vector3(0.2, 0, 0), 0.1)
	tween.tween_property(box, "position", box.position, 0.1)

func show_box_reaction_too_heavy():
	# Create erratic movement animation
	var tween = create_tween()
	tween.tween_property(box, "position", box.position + Vector3(1, 0.5, -1), 0.3)
	tween.tween_property(box, "position", box.position, 0.5)

func reset_interaction():
	await get_tree().create_timer(1.0).timeout
	force_applied = false
	# Optional: reset or keep the current force for next attempt

func create_visual_effect(effect_path, position):
	# Instantiate particle effect or other visual feedback
	# This is a placeholder - implement according to your game's effect system
	return null
