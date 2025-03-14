extends Control

@onready var progress_bar = $ProgressBar
@onready var force_label = $Label

var max_force = 100.0
var current_force = 0.0
var is_active = false
var fade_timer = 0.0
var fade_duration = 1.0

func _ready():
	# Initialize the progress bar
	progress_bar.max_value = max_force
	progress_bar.value = 0
	
	# Hide the indicator initially
	visible = false

func _process(delta):
	# Handle fading when force is no longer applied
	if !is_active and visible:
		fade_timer += delta
		if fade_timer >= fade_duration:
			visible = false
			fade_timer = 0.0
		else:
			# Fade out the indicator
			modulate.a = 1.0 - (fade_timer / fade_duration)

# Show and update the force indicator
func show_force(force_amount, object_name=""):
	current_force = clamp(force_amount, 0.0, max_force)
	progress_bar.value = current_force
	
	# Format the force value to display (convert to Newtons)
	var force_text = "%.1f N" % current_force
	
	# Show object name if provided
	if object_name != "":
		force_label.text = "%s: %s" % [object_name, force_text]
	else:
		force_label.text = force_text
	
	# Show and reset the indicator
	visible = true
	modulate.a = 1.0
	is_active = true
	fade_timer = 0.0
	
	# Adjust color based on force amount (green to yellow to red)
	var force_ratio = current_force / max_force
	var color = Color.GREEN.lerp(Color.RED, force_ratio)
	progress_bar.modulate = color

# Called when force is no longer being applied
func hide_force():
	is_active = false
	# Will start fading out in _process
