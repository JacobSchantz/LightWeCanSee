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
var expansion_count = {
	"x_pos": 0,  # Right side
	"x_neg": 0,  # Left side
	"z_pos": 0,  # Front side
	"z_neg": 0   # Back side
}

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
	
	# Show the face based on player position relative to the box
	if player:
		# Get player position relative to box center (ignoring Y axis)
		var rel_x = player.global_position.x - global_position.x
		var rel_z = player.global_position.z - global_position.z
		
		# Calculate the distance from player to box center
		var distance = Vector2(rel_x, rel_z).length()
		
		# Calculate the box's current size (accounting for scale)
		var box_size_x = 1.0 * scale.x  # Assuming the box is 1 unit in size originally
		var box_size_z = 1.0 * scale.z
		var max_box_dimension = max(box_size_x, box_size_z)
		
		# Only highlight faces if player is within one box size from the edge
		var max_highlight_distance = max_box_dimension + 1.0  # One box size from the edge
		
		if distance < max_highlight_distance:
			# Scale the relative position based on box scale to account for expansion
			var scaled_rel_x = rel_x / scale.x
			var scaled_rel_z = rel_z / scale.z
			
			# Determine which face to show based on which side of the diagonal the player is on
			var visible_face = null
			
			# Add a small epsilon to prevent ambiguity at exact corners
			var epsilon = 0.001
			
			# Handle exact corner cases
			if abs(abs(scaled_rel_x) - abs(scaled_rel_z)) < epsilon:
				# Player is very close to a diagonal line
				# Choose based on which quadrant they're in
				if scaled_rel_x > 0 and scaled_rel_z > 0:
					visible_face = red_face  # Front-right corner, default to front
				elif scaled_rel_x < 0 and scaled_rel_z > 0:
					visible_face = red_face  # Front-left corner, default to front
				elif scaled_rel_x > 0 and scaled_rel_z < 0:
					visible_face = yellow_face  # Back-right corner, default to right
				else:
					visible_face = purple_face  # Back-left corner, default to back
			else:
				# Normal diagonal line check
				if scaled_rel_x > scaled_rel_z and scaled_rel_x > -scaled_rel_z:
					visible_face = yellow_face  # Right face (positive X)
				elif scaled_rel_x < scaled_rel_z and scaled_rel_x < -scaled_rel_z:
					visible_face = green_face   # Left face (negative X)
				elif scaled_rel_z > scaled_rel_x and scaled_rel_z > -scaled_rel_x:
					visible_face = red_face     # Front face (positive Z)
				else:
					visible_face = purple_face  # Back face (negative Z)
			
			# Make the selected face visible
			if visible_face:
				visible_face.visible = true

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
		
		# Set up the face area to handle interactions
		face_area.set_meta("face_index", i)
		
		# Connect signals for interaction
		face_area.input_event.connect(_on_face_area_input_event.bind(i))

# Handle input events on face areas
func _on_face_area_input_event(_camera, event, _click_position, face_index):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		# Get the level script
		var level = get_tree().get_nodes_in_group("level")[0]
		
		# Call the handle_face_interaction method
		if level.has_method("handle_face_interaction"):
			level.handle_face_interaction(face_index)

# Function to expand box size with animation
func toggle_size():
	# Cancel any existing tween
	if box_tween and box_tween.is_valid():
		box_tween.kill()
	
	# Create a new tween
	box_tween = create_tween()
	box_tween.set_ease(Tween.EASE_OUT)
	box_tween.set_trans(Tween.TRANS_CUBIC)
	
	# Find which face is currently visible
	var visible_face_index = -1
	for i in range(faces.size()):
		if faces[i].node.visible:
			visible_face_index = i
			break
	
	# If no face is visible, default to extending in the X direction
	if visible_face_index == -1:
		visible_face_index = 2  # Default to yellow face (right side)
	
	# Get the direction of the visible face
	var extension_direction = faces[visible_face_index].direction
	var face_name = faces[visible_face_index].name
	
	# Determine which side to expand based on direction
	var side_key = ""
	if extension_direction.x > 0:
		side_key = "x_pos"  # Right side
	elif extension_direction.x < 0:
		side_key = "x_neg"  # Left side
	elif extension_direction.z > 0:
		side_key = "z_pos"  # Front side
	elif extension_direction.z < 0:
		side_key = "z_neg"  # Back side
	
	# Calculate the new scale and position
	var current_scale = scale
	var new_scale = current_scale
	var position_offset = Vector3(0, 0, 0)
	
	if side_key == "x_pos" or side_key == "x_neg":
		# X-axis extension
		new_scale.x += 1.0
		position_offset.x = extension_direction.x * 0.75
	elif side_key == "z_pos" or side_key == "z_neg":
		# Z-axis extension
		new_scale.z += 1.0
		position_offset.z = extension_direction.z * 0.75
	
	# Animate to extended size and position
	box_tween.tween_property(self, "scale", new_scale, animation_duration)
	box_tween.parallel().tween_property(self, "position", position + position_offset, animation_duration)
	
	# Increment the expansion count for this side
	expansion_count[side_key] += 1
	is_extended = true
	print("Box extended in direction of " + face_name + " (Expansion #" + str(expansion_count[side_key]) + ")")
	
	# Connect the tween completed signal to update face positions
	box_tween.finished.connect(update_face_world_positions)
