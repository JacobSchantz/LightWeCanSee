extends Node

@onready var http_request = $HTTPRequest
var model_url = "https://example.com/path/to/model.glb"

func _ready():
    # Connect the request_completed signal
    http_request.request_completed.connect(_on_request_completed)
    # Start the download
    http_request.request(model_url)

func _on_request_completed(result, response_code, headers, body):
    if result != HTTPRequest.RESULT_SUCCESS or response_code != 200:
        print("Failed to download file")
        return

    # Save the downloaded file temporarily
    var temp_path = "user://temp_model.glb"
    var file = FileAccess.open(temp_path, FileAccess.WRITE)
    file.store_buffer(body)
    file.close()

    # Load the model as a PackedScene or directly as a mesh
    var loaded_scene = load(temp_path) as PackedScene
    if loaded_scene:
        var model_instance = loaded_scene.instantiate()
        add_child(model_instance)
    else:
        print("Failed to load model")

    # Optionally, clean up the temporary file
    DirAccess.remove_absolute(temp_path)