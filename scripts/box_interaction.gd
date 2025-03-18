extends Area3D

# This script handles the interaction with the box
# It provides a simple toggle for the red face

func _ready():
	# Connect signals for better player feedback (optional)
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _on_body_entered(body):
	if body.is_in_group("player"):
		# Optional: Display prompt or highlight to indicate interactability
		print("Player can interact with box")

func _on_body_exited(body):
	if body.is_in_group("player"):
		# Optional: Hide prompt or remove highlight
		print("Player left box interaction area")

func interact():
	# Get the parent level script
	var level = get_parent()
	
	# Call the level's method to toggle the red face
	if level.has_method("toggle_red_face"):
		level.toggle_red_face()
	else:
		print("Error: Level script doesn't have toggle_red_face method")
