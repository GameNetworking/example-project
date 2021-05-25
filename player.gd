extends KinematicBody3D


const MOVE_SPEED: int = 10
const MOTION_INTERPOLATE_SPEED: int = 20
const VELOCITY_INTERPOLATE_SPEED: int = 2
const GRAVITY: int = 10
const JUMP_IMPULSE: float = 4.0

@onready var camera: PlayerCamera = $Camera

var velocity: Vector3
var on_floor: bool

@onready var mesh_container: Node3D = $MeshContainer
@onready var _mesh: MeshInstance3D = $MeshContainer/Mesh


func set_color(color):
	var mat = _mesh.get_surface_override_material(0)
	if mat == null:
		mat = StandardMaterial3D.new()
	else:
		mat = mat.duplicate()
	mat.set_albedo(Color(color))
	_mesh.set_surface_override_material(0, mat)


 # Computes one motion step.
func step_body(delta: float, input_direction: Vector3, is_jumping: bool):
	_set_player_orientation(input_direction)

	var motion: Vector3 = input_direction * MOVE_SPEED
	var new_velocity: Vector3
	if on_floor and velocity.length() < MOVE_SPEED:
		new_velocity = velocity.lerp(motion, MOTION_INTERPOLATE_SPEED * delta)
		if is_jumping:
			new_velocity.y += JUMP_IMPULSE
	else:
		new_velocity = velocity.lerp(motion, VELOCITY_INTERPOLATE_SPEED * delta)
		new_velocity.y -= GRAVITY * delta

	velocity = move_and_slide(new_velocity, Vector3.UP, true)
	on_floor = is_on_floor() # Store in a variable to sync over network


func _set_player_orientation(input_direction):
	if input_direction.length_squared() < 0.01:
		return
	mesh_container.transform = mesh_container.transform.looking_at(input_direction, Vector3(0, 1, 0))
