extends EditorScript

func _run():
	# Get the currently edited scene
	var scene = get_scene()
	if not scene:
		print("No scene is currently being edited!")
		return
	
	# Check if we're editing the tutorial level
	if scene.name != "TutorialLevel":
		print("This script should be run while editing the tutorial level scene.")
		return
	
	# Load the video wall scene
	var video_wall_scene = load("res://scenes/video_wall.tscn")
	if not video_wall_scene:
		print("Failed to load video_wall.tscn")
		return
	
	# Instance the video wall
	var video_wall = video_wall_scene.instantiate()
	
	# Position it on a wall in the tutorial level (adjust as needed)
	video_wall.transform.origin = Vector3(9, 2.5, 0)  # Position on wall near door
	video_wall.rotation_degrees.y = 90  # Rotate to face inward
	
	# Set video properties (optionally)
	if video_wall.has_method("set_video"):
		video_wall.video_id = "dQw4w9WgXcQ"  # Change to your video ID
		video_wall.autoplay = true
		video_wall.mute = false
	
	# Add to the scene
	scene.add_child(video_wall)
	video_wall.owner = scene
	
	print("Video wall added to the tutorial level!")
