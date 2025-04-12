@tool
extends EditorScript

func _run():
	# Get the tutorial level scene
	var tutorial_level = load("res://scenes/tutorial_level.tscn").instantiate()
	
	# Check if WorldEnvironment already exists
	var world_env = tutorial_level.get_node_or_null("WorldEnvironment")
	if not world_env:
		world_env = WorldEnvironment.new()
		world_env.name = "WorldEnvironment"
		tutorial_level.add_child(world_env)
		world_env.owner = tutorial_level
	
	# Load the shader and sky materials from main scene
	var main_scene = load("res://assets/main.tscn").instantiate()
	var main_env = main_scene.get_node("WorldEnvironment").environment
	
	# Create new environment if needed or use existing
	var env = world_env.environment
	if not env:
		env = Environment.new()
		world_env.environment = env
	
	# Copy sky settings
	env.background_mode = main_env.background_mode  # Should be 2 (Sky)
	env.sky = main_env.sky
	env.ambient_light_source = main_env.ambient_light_source
	
	# Add DirectionalLight (Sun) if it doesn't exist
	var sun = tutorial_level.get_node_or_null("Sun")
	if not sun:
		var main_sun = main_scene.get_node("Sun")
		sun = main_sun.duplicate()
		tutorial_level.add_child(sun)
		sun.owner = tutorial_level
	
	# Save the modified scene
	var packed_scene = PackedScene.new()
	packed_scene.pack(tutorial_level)
	ResourceSaver.save(packed_scene, "res://scenes/tutorial_level.tscn")
	
	print("Skybox added to tutorial_level.tscn successfully!")
