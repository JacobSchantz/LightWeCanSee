extends "res://scripts/base_level.gd"

# Physics puzzle properties
var box_mass = 10.0  # kg
var required_acceleration = 2.0  # m/s²
var correct_force = 20.0  # N (F = m * a = 10 * 2 = 20)

# UI elements
@onready var question_panel = $QuestionUI/Panel
@onready var question_label = $QuestionUI/Panel/QuestionLabel
@onready var options_container = $QuestionUI/Panel/OptionsContainer
@onready var feedback_label = $QuestionUI/Panel/FeedbackLabel
@onready var box = $PhysicsObjects/Box

# Level state
var is_question_active = false
var options = ["10 N", "20 N", "30 N", "50 N"]
var correct_option_index = 1  # Option "20 N" is the correct answer

func _ready():
	super._ready()
	
	# Set level properties
	level_name = "Force Calculation"
	level_description = "Apply the correct force to move the box"
	
	# Hide the question UI initially
	question_panel.visible = false
	feedback_label.text = ""
	
	# Setup box interactable area
	if box.has_node("InteractArea"):
		var interact_area = box.get_node("InteractArea")
		interact_area.connect("body_entered", Callable(self, "_on_box_interaction_area_entered"))

func _on_box_interaction_area_entered(body):
	if body.is_in_group("player") and not is_question_active:
		show_physics_question()

func show_physics_question():
	is_question_active = true
	
	# Set up the question text
	question_label.text = "The box has a mass of 10 kg and needs to be accelerated at 2 m/s² to move out of the way. What force is required?"
	
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
		feedback_label.text = "Correct! F = m * a = 10 kg * 2 m/s² = 20 N"
		feedback_label.modulate = Color.GREEN
		
		# Unpause and hide UI after a delay
		get_tree().paused = false
		await get_tree().create_timer(2.0).timeout
		question_panel.visible = false
		
		# Move the box using animation
		var tween = create_tween()
		tween.tween_property(box, "position", box.position + Vector3(0, 0, -5), 1.5)
		await tween.finished
		
		# Complete the level
		complete_level()
	else:
		feedback_label.text = "Incorrect. Try again!"
		feedback_label.modulate = Color.RED
		
		# Allow to retry
