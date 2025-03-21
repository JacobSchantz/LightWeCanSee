@tool
extends Node

# This script generates a stars texture from a shader
# Run this script from the editor to create the texture

func _ready():
	if Engine.is_editor_hint():
		generate_stars_texture()

func generate_stars_texture():
	# Create a viewport to render the shader
	var viewport = SubViewport.new()
	viewport.size = Vector2(1024, 1024)
	viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
	
	# Create a ColorRect with the shader
	var rect = ColorRect.new()
	rect.size = Vector2(1024, 1024)
	
	# Load the shader
	var shader = load("res://assets/textures/stars_texture.gdshader")
	var material = ShaderMaterial.new()
	material.shader = shader
	rect.material = material
	
	# Add to viewport
	viewport.add_child(rect)
	add_child(viewport)
	
	# Wait for rendering
	await get_tree().process_frame
	await get_tree().process_frame
	
	# Get the texture
	var img = viewport.get_texture().get_image()
	
	# Save the texture
	img.save_png("res://assets/textures/stars_texture.png")
	
	# Clean up
	viewport.queue_free()
	
	print("Stars texture generated successfully!")
