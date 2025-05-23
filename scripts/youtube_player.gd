extends Node

signal video_ready
signal playback_state_changed(is_playing)

# YouTube video settings
var video_id: String = ""
var start_time: int = 0
var is_paused: bool = true
var is_initialized: bool = false

# For web platform
var js_code = """
function setupYouTubePlayer(videoId, startTime) {
  if (window.youTubePlayer) {
	window.youTubePlayer.destroy();
  }
  
  // Create container if it doesn't exist
  let container = document.getElementById('godot-youtube-container');
  if (!container) {
	container = document.createElement('div');
	container.id = 'godot-youtube-container';
	container.style.position = 'absolute';
	container.style.width = '1px';
	container.style.height = '1px';
	container.style.opacity = '0.01';
	container.style.pointerEvents = 'none';
	document.body.appendChild(container);
  }
  
  // Create player
  window.youTubePlayer = new YT.Player(container, {
	videoId: videoId,
	playerVars: {
	  'start': startTime,
	  'autoplay': 0,
	  'controls': 0,
	  'showinfo': 0,
	  'rel': 0,
	  'iv_load_policy': 3,
	  'modestbranding': 1
	},
	events: {
	  'onReady': function(event) {
		window.dispatchEvent(new CustomEvent('youtube_ready'));
	  },
	  'onStateChange': function(event) {
		if (event.data === 1) { // playing
		  window.dispatchEvent(new CustomEvent('youtube_playing'));
		} else if (event.data === 2) { // paused
		  window.dispatchEvent(new CustomEvent('youtube_paused'));
		}
	  }
	}
  });
  
  return true;
}

function loadYouTubeAPI() {
  if (window.YT) {
	return true;
  }
  
  var tag = document.createElement('script');
  tag.src = "https://www.youtube.com/iframe_api";
  var firstScriptTag = document.getElementsByTagName('script')[0];
  firstScriptTag.parentNode.insertBefore(tag, firstScriptTag);
  
  window.onYouTubeIframeAPIReady = function() {
	window.dispatchEvent(new CustomEvent('youtube_api_ready'));
  };
  
  return true;
}

function playYouTubeVideo() {
  if (window.youTubePlayer && window.youTubePlayer.playVideo) {
	window.youTubePlayer.playVideo();
	return true;
  }
  return false;
}

function pauseYouTubeVideo() {
  if (window.youTubePlayer && window.youTubePlayer.pauseVideo) {
	window.youTubePlayer.pauseVideo();
	return true;
  }
  return false;
}

function getCurrentTime() {
  if (window.youTubePlayer && window.youTubePlayer.getCurrentTime) {
	return window.youTubePlayer.getCurrentTime();
  }
  return 0;
}
"""

func _ready():
	# Only run JavaScript code in web exports
	if Engine.has_singleton("JavaScript"):
		var JavaScript = Engine.get_singleton("JavaScript")
		
		# Setup JavaScript callbacks
		JavaScript.create_callback(self, "on_youtube_api_ready")
		JavaScript.create_callback(self, "on_youtube_ready")
		JavaScript.create_callback(self, "on_youtube_playing")
		JavaScript.create_callback(self, "on_youtube_paused")
		
		# Add event listeners
		JavaScript.eval("""
			window.addEventListener('youtube_api_ready', function() {
				window.godot.on_youtube_api_ready();
			});
			window.addEventListener('youtube_ready', function() {
				window.godot.on_youtube_ready();
			});
			window.addEventListener('youtube_playing', function() {
				window.godot.on_youtube_playing();
			});
			window.addEventListener('youtube_paused', function() {
				window.godot.on_youtube_paused();
			});
		""")
		
		# Load YouTube API
		JavaScript.eval("loadYouTubeAPI();")
	else:
		# For non-web platforms, just emit ready immediately
		is_initialized = true
		video_ready.emit()

func initialize_player(id: String, time: int = 0):
	video_id = id
	start_time = time
	is_paused = true
	
	# Only use JavaScript in web exports
	if Engine.has_singleton("JavaScript"):
		var JavaScript = Engine.get_singleton("JavaScript")
		# For web platform, setup YouTube player
		JavaScript.eval("setupYouTubePlayer('" + video_id + "', " + str(start_time) + ");")
	else:
		# For non-web platforms, emit ready event immediately
		is_initialized = true
		video_ready.emit()

func play():
	if not is_initialized:
		return
		
	is_paused = false
	playback_state_changed.emit(true)
	
	# Only use JavaScript in web exports
	if Engine.has_singleton("JavaScript"):
		var JavaScript = Engine.get_singleton("JavaScript")
		JavaScript.eval("playYouTubeVideo();")

func pause():
	if not is_initialized:
		return
		
	is_paused = true
	playback_state_changed.emit(false)
	
	# Only use JavaScript in web exports
	if Engine.has_singleton("JavaScript"):
		var JavaScript = Engine.get_singleton("JavaScript")
		JavaScript.eval("pauseYouTubeVideo();")

func toggle_playback():
	if is_paused:
		play()
	else:
		pause()

# JavaScript callbacks
func on_youtube_api_ready():
	print("YouTube API Ready")
	# API is ready, now we can initialize player
	if video_id != "":
		initialize_player(video_id, start_time)

func on_youtube_ready():
	print("YouTube Player Ready")
	is_initialized = true
	video_ready.emit()

func on_youtube_playing():
	is_paused = false
	playback_state_changed.emit(true)

func on_youtube_paused():
	is_paused = true
	playback_state_changed.emit(false)

func get_current_time():
	# Only use JavaScript in web exports
	if Engine.has_singleton("JavaScript") and is_initialized:
		var JavaScript = Engine.get_singleton("JavaScript")
		return JavaScript.eval("getCurrentTime();")
	return 0

func get_playback_state_text():
	return "PAUSED" if is_paused else "PLAYING"
