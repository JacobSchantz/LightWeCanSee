extends Area3D

# This script handles the interaction logic for each face area
# It's attached to the collision areas that surround each face of the blue box

func _ready():
	# Connect signals for better player feedback (optional)
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _on_body_entered(body):
	if body.is_in_group("player"):
		# Optional: Display prompt or highlight to indicate interactability
		print("Player can interact with " + name)

func _on_body_exited(body):
	if body.is_in_group("player"):
		# Optional: Hide prompt or remove highlight
		print("Player left " + name)

func interact():
	# Get the face index stored as metadata
	var face_index = get_meta("face_index")
	
	# Get the parent level script
	var level = get_tree().get_nodes_in_group("level")[0]
	
	# Call the level's method to activate this face
	if level.has_method("activate_face"):
		level.activate_face(face_index)
	else:
		print("Error: Level script doesn't have activate_face method")
