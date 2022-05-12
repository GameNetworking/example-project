extends NetworkedController
# Take cares to control the player and propagate the motion on the other peers


const MAX_PLAYER_DISTANCE: float = 20.0

var _position_id := -1
var _rotation_id := -1


func _ready():
	# Notify the NetworkSync who is controlling parent nodes.
	NetworkSync.set_node_as_controlled_by(get_parent(), self)
	NetworkSync.register_variable(get_parent(), "translation")
	NetworkSync.register_variable(get_parent(), "velocity")
	NetworkSync.register_variable(get_parent(), "on_floor")
	if not get_tree().get_multiplayer().is_server():
		set_physics_process(false)


func _physics_process(_delta):
	"""
	for character in get_tree().get_nodes_in_group("characters"):
		if character != get_parent():
			var delta_distance = character.get_global_transform().origin - get_parent().get_global_transform().origin

			var is_far_away = delta_distance.length_squared() > (MAX_PLAYER_DISTANCE * MAX_PLAYER_DISTANCE)
			set_doll_peer_active(character.get_network_master(), !is_far_away);
	"""
	pass


func _collect_inputs(_delta: float, db: DataBuffer):
	# Collects the player inputs.

	var input_direction := Vector3()
	var is_jumping: bool = false

	if Input.is_action_pressed("forward"):
		input_direction -= get_parent().camera.global_transform.basis.z
	if Input.is_action_pressed("backward"):
		input_direction += get_parent().camera.global_transform.basis.z
	if Input.is_action_pressed("left"):
		input_direction -= get_parent().camera.global_transform.basis.x
	if Input.is_action_pressed("right"):
		input_direction += get_parent().camera.global_transform.basis.x
	if Input.is_action_pressed("jump"):
		is_jumping = true
	input_direction.y = 0
	input_direction = input_direction.normalized()

	db.add_bool(is_jumping)

	var has_input: bool = input_direction.length_squared() > 0.0
	db.add_bool(has_input)
	if has_input:
		db.add_normalized_vector2(Vector2(input_direction.x, input_direction.z), DataBuffer.COMPRESSION_LEVEL_3)


func _controller_process(delta: float, db: DataBuffer):
	# Process the controller.

	# Take the inputs
	var is_jumping = db.read_bool()
	var input_direction := Vector2()

	var has_input = db.read_bool()
	if has_input:
		input_direction = db.read_normalized_vector2(DataBuffer.COMPRESSION_LEVEL_3)

	# Process the character
	get_parent().step_body(delta, Vector3(input_direction.x, 0.0, input_direction.y), is_jumping)


func _count_input_size(inputs: DataBuffer) -> int:
	# Count the input buffer size.
	var size: int = 0
	size += inputs.get_bool_size()
	inputs.skip_bool()
	size += inputs.get_bool_size()
	if inputs.read_bool():
		size += inputs.get_normalized_vector2_size(DataBuffer.COMPRESSION_LEVEL_3)

	return size


func _are_inputs_different(inputs_A: DataBuffer, inputs_B: DataBuffer) -> bool:
	# Compare two inputs, returns true when those are different or false when are close enough.
	if inputs_A.read_bool() != inputs_B.read_bool():
		return true

	var inp_A_has_i = inputs_A.read_bool()
	var inp_B_has_i = inputs_B.read_bool()
	if inp_A_has_i != inp_B_has_i:
		return true

	if inp_A_has_i:
		var inp_A_dir = inputs_A.read_normalized_vector2(DataBuffer.COMPRESSION_LEVEL_3)
		var inp_B_dir = inputs_B.read_normalized_vector2(DataBuffer.COMPRESSION_LEVEL_3)
		if (inp_A_dir - inp_B_dir).length_squared() > 0.0001:
			return true

	return false


func _collect_epoch_data(buffer: DataBuffer):
	# Called on server when the collect state is triggered.
	# The collected `DataBuffer` is sent to the client that parse it using the
	# function `parse_epoch_data` and puts the data into the interpolator.
	# Later the function `apply_epoch` is called to apply the epoch
	# (already interpolated) data.
	
	# TODO The compression level for the character position should be scaled depending on how close
	# the character is to the local character: It should be 0 when the characters are near each other,
	# to avoid that a collision cause de-sync due to the sliglty different position introduced by the
	# high compression level.
	buffer.add_vector3(get_parent().global_transform.origin, DataBuffer.COMPRESSION_LEVEL_0)
	buffer.add_vector3(get_parent().mesh_container.rotation, DataBuffer.COMPRESSION_LEVEL_2)


func _setup_interpolator(interpolator: Interpolator):
	# Called only on client doll to initialize the `Intepolator`.
	_position_id = interpolator.register_variable(Vector3(), Interpolator.FALLBACK_NEW_OR_NEAREST)
	_rotation_id = interpolator.register_variable(Vector3(), Interpolator.FALLBACK_NEW_OR_NEAREST)


func _parse_epoch_data(interpolator: Interpolator, buffer: DataBuffer):
	# Called locally to parse the `DataBuffer` and store the data into the `Interpolator`.
	var position := buffer.read_vector3(DataBuffer.COMPRESSION_LEVEL_0)
	var rotation := buffer.read_vector3(DataBuffer.COMPRESSION_LEVEL_2)
	interpolator.epoch_insert(_position_id, position)
	interpolator.epoch_insert(_rotation_id, rotation)


func _apply_epoch(_delta: float, interpolated_data: Array):
	# Happens only on doll client each frame. Here is necessary to apply the _already interpolated_ values.
	get_parent().global_transform.origin = interpolated_data[_position_id]
	get_parent().mesh_container.rotation = interpolated_data[_rotation_id]
