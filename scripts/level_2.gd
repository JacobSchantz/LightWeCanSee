extends "res://scripts/base_level.gd"

# Physics puzzle properties
var weight1_mass = 20.0  # kg
var weight1_distance = 2.0  # meters from fulcrum
var weight2_mass = 10.0  # kg
var correct_distance = 4.0  # meters from fulcrum (calculated from the principle of moments)

# Interactive properties
var is_player_near_lever = false
var is_holding_weight = false
var current_position = 1.0  # starting position in meters from fulcrum
var position_increment = 0.5  # move in half-meter increments
var max_position = 5.0
var is_balanced = false

# Visual feedback
@onready var lever = $PhysicsObjects/Lever
@onready var weight1 = $PhysicsObjects/Weight1
@onready var weight2 = $PhysicsObjects/Weight2
@onready var distance_markers = $PhysicsObjects/DistanceMarkers
@onready var position_indicator = $PhysicsObjects/PositionIndicator
@onready var mass_label1 = $PhysicsObjects/MassLabel1
@onready var mass_label2 = $PhysicsObjects/MassLabel2

# Sound effects
@onready var success_sound = $Sounds/SuccessSound
@onready var move_sound = $Sounds/MoveSound
@onready var pick_sound = $Sounds/PickSound
@onready var place_sound = $Sounds/PlaceSound

func _ready():
	super._ready()
	
	# Set level properties
	level_name = "Lever Balance"
	level_description = "Balance the lever by placing the weight at the correct distance"
	
	# Setup lever interactable area
	if lever.has_node("InteractArea"):
		var interact_area = lever.get_node("InteractArea")
		interact_area.connect("body_entered", Callable(self, "_on_lever_interaction_area_entered"))
		interact_area.connect("body_exited", Callable(self, "_on_lever_interaction_area_exited"))
	
	# Setup visual cues
	update_mass_labels()
	
	# Position the first weight (fixed)
	position_weight(weight1, weight1_distance)
	
	# Position the second weight initially
	position_weight(weight2, current_position)
	
	# Show distance markers along the lever
	setup_distance_markers()
	
	# Set initial lever tilt based on the imbalance
	update_lever_tilt()

func _process(delta):
	if is_player_near_lever and not is_balanced:
		# Player interaction with weights
		if Input.is_action_just_pressed("interact"):
			toggle_hold_weight()
		
		# Move weight left/right when held
		if is_holding_weight:
			if Input.is_action_just_pressed("ui_right") and current_position < max_position:
				current_position += position_increment
				position_weight(weight2, current_position)
				play_move_sound()
				update_lever_tilt()
			
			if Input.is_action_just_pressed("ui_left") and current_position > position_increment:
				current_position -= position_increment
				position_weight(weight2, current_position)
				play_move_sound()
				update_lever_tilt()
		
		# Check for balance confirmation
		if Input.is_action_just_pressed("ui_accept") and not is_holding_weight:
			check_balance()

func _on_lever_interaction_area_entered(body):
	if body.is_in_group("player"):
		is_player_near_lever = true
		# Show a subtle highlight or hint
		if position_indicator:
			position_indicator.visible = true

		# Display a subtle hint about what to do
		show_hint("Move the weight to balance the lever")

func _on_lever_interaction_area_exited(body):
	if body.is_in_group("player"):
		is_player_near_lever = false
		if position_indicator:
			position_indicator.visible = false
		
		# Hide any hints
		hide_hint()

func update_mass_labels():
	if mass_label1:
		mass_label1.text = str(weight1_mass) + " kg"
	if mass_label2:
		mass_label2.text = str(weight2_mass) + " kg"

func position_weight(weight, distance):
	# Position the weight along the lever at the specified distance
	weight.position.x = distance
	
	# Update indicator if available
	if position_indicator and weight == weight2:
		position_indicator.position.x = distance
		if position_indicator.has_node("DistanceLabel"):
			position_indicator.get_node("DistanceLabel").text = str(distance) + " m"

func toggle_hold_weight():
	is_holding_weight = !is_holding_weight
	
	# Visual feedback for holding
	if is_holding_weight:
		weight2.scale = Vector3(1.1, 1.1, 1.1)  # Slight increase to show it's selected
		if pick_sound:
			pick_sound.play()
	else:
		weight2.scale = Vector3(1, 1, 1)
		if place_sound:
			place_sound.play()

func update_lever_tilt():
	# Calculate lever tilt based on the torque differential
	var torque1 = weight1_mass * weight1_distance
	var torque2 = weight2_mass * current_position
	
	var torque_diff = torque1 - torque2
	var max_tilt = 20.0  # Maximum tilt angle in degrees
	
	# Map the torque difference to a tilt angle
	var tilt_factor = clamp(torque_diff / (weight1_mass * weight1_distance), -1, 1)
	var tilt_angle = tilt_factor * max_tilt
	
	# Apply tilt to the lever
	var tween = create_tween()
	tween.tween_property(lever, "rotation_degrees:z", tilt_angle, 0.3)
	
	# Check for near-balance (within 5% error)
	var balance_error = abs(torque_diff) / torque1
	if balance_error < 0.05:
		# Give a subtle visual hint that it's close
		if position_indicator:
			position_indicator.modulate = Color.GREEN
	else:
		if position_indicator:
			position_indicator.modulate = Color.WHITE

func check_balance():
	# Calculate if the lever is balanced (torques are equal)
	var torque1 = weight1_mass * weight1_distance
	var torque2 = weight2_mass * current_position
	
	var balance_error = abs(torque1 - torque2) / torque1
	
	if balance_error <= 0.05:  # Within 5% of perfect balance
		is_balanced = true
		
		# Play success sound
		if success_sound:
			success_sound.play()
		
		# Balance the lever perfectly
		var tween = create_tween()
		tween.tween_property(lever, "rotation_degrees", Vector3(0, 0, 0), 1.0)
		await tween.finished
		
		# Show formula visualization (optional)
		show_balance_formula()
		
		# Complete the level
		complete_level()
	else:
		# Not balanced - give physical feedback
		var tween = create_tween()
		
		# Exaggerate the tilt briefly to show it's not balanced
		var current_tilt = lever.rotation_degrees.z
		tween.tween_property(lever, "rotation_degrees:z", current_tilt * 1.5, 0.2)
		tween.tween_property(lever, "rotation_degrees:z", current_tilt, 0.3)

func setup_distance_markers():
	if distance_markers:
		# Place visual markers at each distance point
		for i in range(1, int(max_position) + 1):
			# Create marker at position i
			# This is a placeholder - implement according to your game's marker system
			pass

func show_balance_formula():
	# Optional - show a subtle visualization of m₁ * d₁ = m₂ * d₂
	# This could be a small floating text or particle effect
	pass

func play_move_sound():
	if move_sound and not move_sound.playing:
		move_sound.play()

func show_hint(text):
	# Show a subtle hint to the player
	# This is a placeholder - implement according to your game's hint system
	pass

func hide_hint():
	# Hide any active hints
	# This is a placeholder - implement according to your game's hint system
	pass
