class_name Hand extends Node3D

const FREE = States.FREE 
const NEWSPAPER = States.NEWSPAPER
const BETTING = States.BETTING

enum States {
	FREE,
	NEWSPAPER,
	BETTING
}

var state: States = FREE
var default_z_plane_depth
var anim_locked: bool = false
var bet_tween: Tween
var last_position: Vector3
@onready var animator := $AnimationPlayer2

@export
var max_speed := 10

func _ready() -> void:
	default_z_plane_depth = position.z - get_viewport().get_camera_3d().position.z

func _input(event: InputEvent) -> void:
	if event.is_action(&"menu"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _process(delta: float) -> void:
	DebugDraw2D.set_text("hand_state", States.find_key(state))
	match state:
		FREE: 
			_move_to_mouse(delta)
		NEWSPAPER:
			_move_to_mouse(delta)
			
		BETTING:
			if global_position.is_equal_approx($"../../BettingArea".global_position) or (bet_tween and bet_tween.is_valid()):
				return
			bet_tween = create_tween().set_parallel()
			bet_tween.tween_property(self, ^"position", $"../../BettingArea".position, 0.25)
			bet_tween.tween_property(self, ^"rotation", $"../../BettingArea".rotation, 0.25)

#func _physics_process(delta: float) -> void:
	#last_position = position

func _move_to_mouse(delta: float) -> void:
	var mouse_pos := get_viewport().get_camera_3d().project_position(get_viewport().get_mouse_position(), default_z_plane_depth)
	mouse_pos += Vector3.DOWN * 0.05
	last_position = position
	position = position.move_toward(position.lerp(mouse_pos, 0.2), max_speed * delta)

func _on_area_3d_area_entered(area: Area3D) -> void:
	if anim_locked:
		return
	if "Betting" in area.name:
		#TODO REPLACE WITH HAND TYPING ANIMATION
		animator.play(&"hand_animation_library/hand_default")
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		state = BETTING
		$"../Sofa/Newspaper".visible = true
	elif "News" in area.name:
		animator.play(&"hand_animation_library/hand_newspaper")
		Input.mouse_mode = Input.MOUSE_MODE_CONFINED_HIDDEN
		$"../Sofa/Newspaper".visible = false
		state = NEWSPAPER

func _on_area_3d_area_exited(area: Area3D) -> void:
	if "Betting" in area.name and state == BETTING:
		animator.play(&"hand_animation_library/hand_default")
		Input.mouse_mode = Input.MOUSE_MODE_CONFINED_HIDDEN
		state = FREE
		rotation = Vector3.ZERO
		if bet_tween:
			bet_tween.kill()
	elif "News" in area.name:
		$"../Sofa/Newspaper".visible = true
		animator.play(&"hand_animation_library/hand_default")
		state = FREE

func _on_gui_panel_3d_mouse_entered() -> void:
	if state != BETTING:
		_on_area_3d_area_entered($"../../BettingArea")

func _on_gui_panel_3d_mouse_exited() -> void:
	if state == BETTING:
		_on_area_3d_area_exited($"../../BettingArea")

func _on_newspaper_area_area_entered(area: Area3D) -> void:
	if "Slap" in area.name:
		var speed := position.distance_to(last_position)
		DebugDraw2D.set_text("slap_vel", speed / get_process_delta_time())
