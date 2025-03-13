extends "res://scripts/base_level.gd"

# Physics puzzle properties
var weight1_mass = 20.0  # kg
var weight1_distance = 2.0  # meters from fulcrum
var weight2_mass = 10.0  # kg
var correct_distance = 4.0  # meters from fulcrum (calculated from the principle of moments)

# UI elements
@onready var question_panel = $QuestionUI/Panel
@onready var question_label = $QuestionUI/Panel/QuestionLabel
@onready var options_container = $QuestionUI/Panel/OptionsContainer
@onready var feedback_label = $QuestionUI/Panel/FeedbackLabel
@onready var lever = $PhysicsObjects/Lever
@onready var weight1 = $PhysicsObjects/Weight1
@onready var weight2 = $PhysicsObjects/Weight2

# Level state
var is_question_active = false
var options = ["1 m", "2 m", "3 m", "4 m"]
var correct_option_index = 3  # Option "4 m" is the correct answer

func _ready():
	super._ready()
	
	# Set level properties
	level_name = "Lever Balance"
	level_description = "Balance the lever by placing the weight at the correct distance"
	
	# Hide the question UI initially
	question_panel.visible = false
	feedback_label.text = ""
	
	# Setup lever interactable area
	if lever.has_node("InteractArea"):
		var interact_area = lever.get_node("InteractArea")
		interact_area.connect("body_entered", Callable(self, "_on_lever_interaction_area_entered"))

func _on_lever_interaction_area_entered(body):
	if body.is_in_group("player") and not is_question_active:
		show_physics_question()

func show_physics_question():
	is_question_active = true
	
	# Set up the question text
	question_label.text = "Where should you place a 10 kg weight to balance a 20 kg weight positioned 2 meters from the fulcrum?"
	
	# Clear previous options
	for child in options_container.get_children():
		child.queue_free()
	
	# Add option buttons
	for i in range(options.size()):
		var button = Button.new()
		button.text = options[i]
		button.connect("pressed", Callable(self, "_on_option_selected").bind(i))
		options_container.add_child(button)
	
	# Show the question panel
	question_panel.visible = true
	
	# Pause the game while answering (optional)
	get_tree().paused = true

func _on_option_selected(index):
	if index == correct_option_index:
		feedback_label.text = "Correct! m₁ * d₁ = m₂ * d₂, so 20 kg * 2 m = 10 kg * d₂, d₂ = 4 m"
		feedback_label.modulate = Color.GREEN
		
		# Unpause and hide UI after a delay
		get_tree().paused = false
		await get_tree().create_timer(2.0).timeout
		question_panel.visible = false
		
		# Move the weight to the correct position and balance the lever
		var tween = create_tween()
		tween.tween_property(weight2, "position", Vector3(4, 0.5, 0), 1.5)
		await tween.finished
		
		# Animate the lever balancing
		tween = create_tween()
		tween.tween_property(lever, "rotation_degrees", Vector3(0, 0, 0), 1.0)
		await tween.finished
		
		# Complete the level
		complete_level()
	else:
		feedback_label.text = "Incorrect. Try again!"
		feedback_label.modulate = Color.RED
		
		# Allow to retry
