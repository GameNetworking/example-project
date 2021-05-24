extends MeshInstance3D
# Move the box in sync with all peers


var seek: float:
	set = set_seek,
	get = get_seek


@onready var _player: AnimationPlayer = $AnimationPlayer


func _ready():
	NetworkSync.register_process(self, "_sync_process")
	NetworkSync.register_variable(self, "seek", "_on_seek_changed", NetworkSync.SYNC_RESET)

	# Manual process so we can process the animations in sync.
	_player.playback_process_mode = AnimationPlayer.ANIMATION_PROCESS_MANUAL


func get_seek() -> float:
	return _player.get_current_animation_position()


func set_seek(s):
	_player.seek(s)


func _sync_process(delta: float):
	_player.advance(delta)


func _on_seek_changed():
	## This function is called only when a reset occurs thanks to: NetworkSync.SYNC_RESET
	## In alternative you can use this function instead
	## ```
	## if NetworkSync.is_resetted():
	## 	_player.seek(seek)
	## ```

	_player.seek(seek)
