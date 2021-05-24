extends KinematicBody3D


const MAX_SPEED: float = 5
const ACCELERATION: float = 500
const GRAVITY: float = -10

@onready var camera: PlayerCamera = $Camera

var _horizontal_velocity: Vector3
var _gravity: float = 0

var _lines = 0

@onready var mesh_container: Node3D = $MeshContainer
@onready var _mesh: MeshInstance3D = $MeshContainer/Mesh

@onready var _ig = $debug/IG
@onready var _ig_path = $debug/IG_path
@onready var _ig_dir = $debug/IG_dir
@onready var _ig_floor = $debug/IG_floor


func set_color(color):
	var mat = _mesh.get_surface_override_material(0)
	if mat == null:
		mat = StandardMaterial3D.new()
	else:
		mat = mat.duplicate()
	mat.set_albedo(Color(color))
	_mesh.set_surface_override_material(0, mat)


func step_body(delta: float, input_direction: Vector3):
	# Computes one motion step.

	_set_player_orientation(input_direction)

	# Computes friction decelleration
	_horizontal_velocity -= _horizontal_velocity.normalized() * ((_horizontal_velocity.length()/MAX_SPEED) * ACCELERATION * delta)
	# Accelerate toward the new velocity, the combination of ACCELERATION and
	# decelleration will converge to the `MAX_SPEED`
	_horizontal_velocity += input_direction * (ACCELERATION * delta)

	# Compute GRAVITY velocity
	_gravity += GRAVITY * delta

	var on_floor_velocity = Vector3()
	if is_on_floor():
		on_floor_velocity = _horizontal_velocity.slide(get_floor_normal()).normalized()
	var velocity = on_floor_velocity * _horizontal_velocity.length()
	velocity[1] += _gravity

	_ig.set_transform(get_global_transform())
	_ig.clear()
	_ig.begin(Mesh.PRIMITIVE_LINES)
	_ig.add_vertex(Vector3())
	_ig.add_vertex(velocity)
	_ig.end()

	_ig_floor.set_transform(get_global_transform())
	_ig_floor.clear()
	_ig_floor.begin(Mesh.PRIMITIVE_LINES)
	_ig_floor.add_vertex(Vector3())
	_ig_floor.add_vertex(get_floor_normal())
	_ig_floor.end()

	_ig_dir.set_transform(get_global_transform())
	_ig_dir.clear()
	_ig_dir.begin(Mesh.PRIMITIVE_LINES)
	_ig_dir.add_vertex(Vector3())
	_ig_dir.add_vertex(input_direction)
	_ig_dir.end()

	_ig_path.set_transform(Transform())
	_lines += 1
	if _lines % 100 >= 99:
		_ig_path.clear()
	_ig_path.begin(Mesh.PRIMITIVE_LINES)
	_ig_path.add_vertex(get_global_transform().origin - Vector3(0, 0, 0))

	move_and_slide(
		velocity,
		Vector3(0, 1, 0),
		true,
		4,
		deg2rad(47),
		true)

	if is_on_floor():
		_gravity = 0

	_ig_path.add_vertex(get_global_transform().origin - Vector3(0, 0, 0))
	_ig_path.end()


func _set_player_orientation(input_direction):
	if input_direction.length_squared() < 0.01:
		return
	mesh_container.transform = mesh_container.transform.looking_at(input_direction, Vector3(0, 1, 0))
