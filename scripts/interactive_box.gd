extends StaticBody3D

# Face nodes
@onready var red_face = $RedFace
@onready var green_face = $GreenFace
@onready var yellow_face = $YellowFace
@onready var purple_face = $PurpleFace

# Face offset
const FACE_OFFSET = 0.76  # Offset for all faces

# Face interaction variables
var current_face_visible = null
var interaction_area = null
var face_areas = []

# Face data for raycast detection
var faces = []

# Proximity detection
var player = null
var detection_radius = 2.0  # Detection radius for all faces

# Box extension variables
var is_extended = false
var box_tween = null
var animation_duration = 0.3  # Animation duration in seconds

func _ready():
	# Add this box to the extendable_box group
	add_to_group("extendable_box")
	
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
	update_face_world_positions()
	
	# Create interaction areas for each face
	create_face_interaction_areas()
	
	# Find player reference (deferred to ensure scene is ready)
	call_deferred("find_player")

func update_face_world_positions():
	# Update the world positions of all faces
	for i in range(faces.size()):
		faces[i].world_pos = global_position + faces[i].direction * FACE_OFFSET * scale

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
		
		# Update face world positions (in case box moved or scaled)
		update_face_world_positions()
		
		# Find the closest face
		for i in range(faces.size()):
			var distance = player.global_position.distance_to(faces[i].world_pos)
			
			if distance < closest_distance:
				closest_distance = distance
				closest_face_index = i
		
		# Make the closest face visible if within detection radius
		if closest_face_index >= 0 and closest_distance < detection_radius:
			faces[closest_face_index].node.visible = true

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
	interaction_area.global_position = global_position
	
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
		var face_position = global_position + face_data.direction * 0.8
		face_area.global_position = face_position
        
		# Rotate the face area to match the face orientation
		if face_data.direction.x != 0:
			face_area.rotation_degrees.y = 90 if face_data.direction.x > 0 else -90
		elif face_data.direction.z < 0:
			face_area.rotation_degrees.y = 180
        
		# Add to face areas array
		face_areas.append(face_area)
		
		# Set up the face area with the script
		face_area.set_script(load("res://scripts/face_area.gd"))
		face_area.set_meta("face_index", i)

# Function to toggle box size with animation
func toggle_size():
	# Cancel any existing tween
	if box_tween and box_tween.is_valid():
		box_tween.kill()
	
	# Create a new tween
	box_tween = create_tween()
	box_tween.set_ease(Tween.EASE_OUT)
	box_tween.set_trans(Tween.TRANS_CUBIC)
	
	# Toggle the box scale
	if not is_extended:
		# Animate to extended size and position
		box_tween.tween_property(self, "scale", Vector3(2.0, 1.0, 1.0), animation_duration)
		box_tween.parallel().tween_property(self, "position:x", position.x + 0.75, animation_duration)
		is_extended = true
		print("Box size doubled")
	else:
		# Animate back to original size and position
		box_tween.tween_property(self, "scale", Vector3(1.0, 1.0, 1.0), animation_duration)
		box_tween.parallel().tween_property(self, "position:x", position.x - 0.75, animation_duration)
		is_extended = false
		print("Box size restored")
	
	# Connect the tween completed signal to update face positions
	box_tween.finished.connect(update_face_world_positions)
