extends Node3D

# YouTube video settings
@export var video_id: String = "dQw4w9WgXcQ"  # Default video - Rick Roll
@export var autoplay: bool = false
@export var loop: bool = true
@export var mute: bool = false
@export var video_width: int = 854
@export var video_height: int = 480
@export var start_time: int = 0  # Start time in seconds

# HTML content for the iframe
var html_iframe: String = ""

func _ready():
	# Update viewport size to match video dimensions
	$VideoViewport.size = Vector2i(video_width, video_height)
	
	# Generate the iframe HTML
	generate_iframe()
	
	# If we're on a platform that supports JavaScript evaluation
	if OS.has_feature("web"):
		# For web exports, we can use JavaScript directly
		update_web_iframe()
	else:
		# For non-web platforms, show placeholder
		show_placeholder()

func generate_iframe():
	# Create the YouTube embed URL with parameters
	var params = []
	if autoplay:
		params.append("autoplay=1")
	if loop:
		params.append("loop=1")
		# For looping to work, we need to specify the video as a playlist
		params.append("playlist=" + video_id)
	if mute:
		params.append("mute=1")
	if start_time > 0:
		params.append("start=" + str(start_time))
	
	# Add standard parameters
	params.append("rel=0")  # Don't show related videos
	params.append("controls=1")  # Show video controls
	
	# Join all parameters
	var param_string = "?" + "&".join(params)
	
	# Build the full iframe HTML
	html_iframe = """
	<!DOCTYPE html>
	<html>
	<head>
		<style>
			body { margin: 0; overflow: hidden; background-color: #000; }
			iframe { width: 100%; height: 100%; border: none; }
		</style>
	</head>
	<body>
		<iframe 
			src="https://www.youtube.com/embed/{video_id}{params}"
			frameborder="0" 
			allowfullscreen>
		</iframe>
	</body>
	</html>
	""".format({"video_id": video_id, "params": param_string})

func update_web_iframe():
	# This only works in HTML5 exports
	# Uses JavaScript to update the iframe content
	JavaScript.eval("""
		var container = document.querySelector('#godot-container');
		var iframe = document.createElement('iframe');
		iframe.src = 'https://www.youtube.com/embed/{video_id}';
		iframe.style.position = 'absolute';
		iframe.style.width = '100%';
		iframe.style.height = '100%';
		iframe.style.border = 'none';
		container.appendChild(iframe);
	""".format({"video_id": video_id}))

func show_placeholder():
	# For non-web platforms, show a placeholder with video info
	var placeholder = $VideoViewport/Control/ColorRect
	
	# Create a label to show info
	var label = Label.new()
	$VideoViewport/Control.add_child(label)
	
	label.text = "YouTube Video\nID: " + video_id
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_color_override("font_color", Color(1, 1, 1))
	label.add_theme_font_size_override("font_size", 24)
	
	# Make the label fill the viewport
	label.anchor_left = 0
	label.anchor_top = 0
	label.anchor_right = 1
	label.anchor_bottom = 1
	label.grow_horizontal = 2
	label.grow_vertical = 2

# Call this to change the video at runtime
func set_video(new_id: String):
	video_id = new_id
	generate_iframe()
	
	if OS.has_feature("web"):
		update_web_iframe()
	else:
		# Update the placeholder text
		var label = $VideoViewport/Control.get_node("Label")
		if label:
			label.text = "YouTube Video\nID: " + video_id
