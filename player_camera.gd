class_name PlayerCamera
extends SpringArm3D


const MOUSE_ROTATION_SPEED := 0.002
const ZOOM_SPEED := 0.5

@onready var _camera: Camera3D = $Camera

var _captured: bool


func _ready() -> void:
	if is_multiplayer_authority():
		_camera.current = true
	else:
		set_process_input(false)


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cursor"):
		if _captured:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		_captured = !_captured
	elif event.is_action_pressed("zoom_in"):
		spring_length += ZOOM_SPEED
	elif event.is_action_pressed("zoom_out"):
		spring_length -= ZOOM_SPEED
	elif _captured and event is InputEventMouseMotion:
		rotation.y -= event.relative.x * MOUSE_ROTATION_SPEED
		rotation.x -= event.relative.y * MOUSE_ROTATION_SPEED
		rotation.x = clamp(rotation.x, -PI / 2, 0.7)
