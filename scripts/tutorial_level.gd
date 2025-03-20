extends "res://scripts/base_level.gd"

# UI elements
@onready var tutorial_ui = $TutorialUI
@onready var instruction_label = $TutorialUI/InstructionPanel/InstructionLabel
@onready var progress_label = $TutorialUI/ProgressLabel
@onready var blue_box = $PhysicsObjects/BlueBox
@onready var red_face = $PhysicsObjects/BlueBox/RedFace
@onready var green_face = $PhysicsObjects/BlueBox/GreenFace
@onready var yellow_face = $PhysicsObjects/BlueBox/YellowFace
@onready var purple_face = $PhysicsObjects/BlueBox/PurpleFace

# Face offset
const FACE_OFFSET = 0.76  # Offset for all faces

# Face interaction variables
var current_face_visible = null
var interaction_area = null
var face_areas = []

# Face data for raycast detection
var faces = []

# Proximity detection
var proximity_areas = []
var player = null
var detection_radius = 2.0  # Detection radius for all faces

func _ready():
	super._ready()
	
	# Add this level to the "level" group for face areas to find it
	add_to_group("level")
	
	# Set level properties
	level_name = "Tutorial"
	level_description = "Tutorial Level"
	
	# Initialize UI
	update_instruction("Welcome to the tutorial level! Move around the box - the closest face will light up.")
	update_progress("Tutorial Level")
	
	# Initialize faces array with face nodes and their directions
	faces = [
		{"node": red_face, "direction": Vector3(0, 0, 1), "name": "Red Face", "world_pos": Vector3()},
		{"node": green_face, "direction": Vector3(-1, 0, 0), "name": "Green Face", "world_pos": Vector3()},
		{"node": yellow_face, "direction": Vector3(1, 0, 0), "name": "Yellow Face", "world_pos": Vector3()},
		{"node": purple_face, "direction": Vector3(0, 0, -1), "name": "Purple Face", "world_pos": Vector3()}
	]
	
	# Make all faces hidden initially
	for face_data in faces:
		face_data.node.visible = false
	
	# Set face positions
	red_face.position = Vector3(0, 0, FACE_OFFSET)  # Front position
	green_face.position = Vector3(-FACE_OFFSET, 0, 0)  # Left position
	yellow_face.position = Vector3(FACE_OFFSET, 0, 0)  # Right position
	purple_face.position = Vector3(0, 0, -FACE_OFFSET)  # Back position
	
	# Calculate world positions for each face
	for i in range(faces.size()):
		faces[i].world_pos = blue_box.global_position + faces[i].direction * FACE_OFFSET
	
	# Create interaction areas for each face
	create_face_interaction_areas()
	
	# Find player reference (deferred to ensure scene is ready)
	call_deferred("find_player")

func find_player():
	# Wait a frame to ensure the player is fully initialized
	await get_tree().process_frame
	
	# Find the player in the scene
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player = players[0]

func _process(_delta):
	# First hide all faces
	for face_data in faces:
		face_data.node.visible = false
	
	# Show the closest face if player is close enough
	if player:
		var closest_face_index = -1
		var closest_distance = 999999.0
		
		# Find the closest face
		for i in range(faces.size()):
			var distance = player.global_position.distance_to(faces[i].world_pos)
			
			if distance < closest_distance:
				closest_distance = distance
				closest_face_index = i
		
		# Make the closest face visible if within detection radius
		if closest_face_index >= 0 and closest_distance < detection_radius:
			faces[closest_face_index].node.visible = true
			
			# Debug output
			print("Closest face: " + faces[closest_face_index].name + " - Distance: " + str(closest_distance))

func create_face_interaction_areas():
	# Create a large Area3D around the box
	interaction_area = Area3D.new()
	interaction_area.name = "BoxInteractionArea"
	interaction_area.collision_layer = 2  # Set to interactable layer
	interaction_area.collision_mask = 1   # Detect player
	add_child(interaction_area)
	
	# Create and set up collision shape for the area
	var shape = CollisionShape3D.new()
	var box_shape = BoxShape3D.new()
	box_shape.size = Vector3(3.5, 3.5, 3.5)  # Large enough to be detected from ~1 cube away
	shape.shape = box_shape
	interaction_area.add_child(shape)
	
	# Center it on the box
	interaction_area.global_position = blue_box.global_position
	
	# Add interact method to the area
	interaction_area.set_script(preload("res://scripts/box_interaction.gd"))
	
	# Create individual face areas for more precise interaction
	for i in range(faces.size()):
		var face_data = faces[i]
		var face_area = Area3D.new()
		face_area.name = "FaceArea" + str(i)
		add_child(face_area)
		
		# Create collision shape for the face area
		var face_shape = CollisionShape3D.new()
		var face_box_shape = BoxShape3D.new()
		face_box_shape.size = Vector3(0.8, 0.8, 0.2)  # Thin box for the face
		face_shape.shape = face_box_shape
		face_area.add_child(face_shape)
		
		# Position the face area
		var face_position = blue_box.global_position + face_data.direction * 0.8
		face_area.global_position = face_position
		
		# Rotate the face area to match the face orientation
		if face_data.direction.x != 0:
			face_area.rotation_degrees.y = 90 if face_data.direction.x > 0 else -90
		elif face_data.direction.z < 0:
			face_area.rotation_degrees.y = 180
		
		# Add to face areas array
		face_areas.append(face_area)
		
		# Store face index as metadata
		face_area.set_meta("face_index", i)
		
		# Add script to the face area
		face_area.set_script(preload("res://scripts/face_area.gd"))

# Method to toggle the visibility of the face the player is looking at
func toggle_face_visibility(face_index):
	if face_index >= 0 and face_index < faces.size():
		var face_data = faces[face_index]
		face_data.node.visible = !face_data.node.visible
		
		if face_data.node.visible:
			update_instruction("You toggled the " + face_data.name + " to visible! Look at any face and press E to toggle it.")
		else:
			update_instruction("You toggled the " + face_data.name + " to hidden! Look at any face and press E to toggle it.")

# Method called by face_area.gd script
func activate_face(face_index):
	toggle_face_visibility(face_index)

func update_instruction(text):
	if instruction_label:
		instruction_label.text = text

func update_progress(text):
	if progress_label:
		progress_label.text = text

func complete_level():
	# Override the base level's complete_level function
	get_tree().call_group("level_manager", "load_next_level")
