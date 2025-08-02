class_name Hand extends Node3D

var default_z_plane_depth

@export
var max_speed := 10

func _ready() -> void:
	default_z_plane_depth = position.z - get_viewport().get_camera_3d().position.z

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		Input.mouse_mode = Input.MOUSE_MODE_CONFINED_HIDDEN
	if event.is_action(&"menu"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _process(delta: float) -> void:
	var mouse_pos := get_viewport().get_camera_3d().project_position(get_viewport().get_mouse_position(), default_z_plane_depth)
	position = position.move_toward(position.lerp(mouse_pos, 0.1), max_speed * delta)
