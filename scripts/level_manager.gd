extends Node3D

var current_level = 0
var levels = []
@onready var transition_animation = $TransitionAnimation
@onready var level_container = $LevelContainer

# Called when the node enters the scene tree for the first time
func _ready():
	# Register the levels
	levels = [
		preload("res://scenes/level_1.tscn"),
		preload("res://scenes/level_2.tscn"),
		preload("res://scenes/force_demo.tscn")
	]
	
	load_level(current_level)



func load_level(level_index):
	if level_index < 0 or level_index >= levels.size():
		print("Level index out of range!")
		return
		
	# Clear any existing level
	for child in level_container.get_children():
		level_container.remove_child(child)
		child.queue_free()
		
	# Instantiate and add the new level
	var level_instance = levels[level_index].instantiate()
	level_container.add_child(level_instance)
	
	# Connect the level completed signal
	if level_instance.has_signal("level_completed"):
		level_instance.connect("level_completed", Callable(self, "_on_level_completed"))
	
	current_level = level_index
	print("Loaded level: ", current_level + 1)

func _on_level_completed():
	# Play transition animation if we have one
	if transition_animation:
		transition_animation.play("fade_out")
		await transition_animation.animation_finished
		
	# Go to next level
	var next_level = current_level + 1
	if next_level < levels.size():
		load_level(next_level)
	else:
		# Game completed
		print("Congratulations! All levels completed!")
		# TODO: Show game completion screen
		
	if transition_animation:
		transition_animation.play("fade_in")

# Debug keys to manually switch levels
func _input(event):
	# Level switching debug keys
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_F1:
			load_level(0)  # Load level 1
		elif event.keycode == KEY_F2:
			load_level(1)  # Load level 2


