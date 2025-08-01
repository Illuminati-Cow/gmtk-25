class_name HorseController3D extends RigidBody3D

enum MoveMode
{
	WALK,
	RUN,
}

@export_category("Movement")
@export_range(0, 10, 0.25) var walk_speed: float = 1
@export_range(0, 10, 0.25) var run_speed: float = 1
@export var acceleration: float = 1
@export var max_acceleration: float = 1
@export var backward_walk_speed_modifier: float = 0.5
@export var rotate_speed: float = 1
@export var speed_dir_curve: Curve

@export_group("Physics")
@export var ride_height: float :
	set(value):
		ride_height = value
		if groundcast:
			groundcast.target_position.y = -value
		
@export var ride_spring_strength: float
@export var ride_spring_damper: float
@export var acceleration_dir_factor: Curve

@export_group("")

@export_category("Debug")
@export
var debug_path: bool:
	get:
		return nav.debug_enabled if nav else false
	set(value):
		debug_path = value
		if nav:
			nav.debug_enabled = value

@onready var nav: NavigationAgent3D = $NavigationAgent3D
@onready var collider: CollisionShape3D = $CollisionShape3D
@onready var groundcast = $GroundCast

var goal_velocity: Vector3
var navigating: bool = false
var _move_modifier: float
var move_mode: MoveMode:
	get:
		return move_mode
	set(value):
		move_mode = value
		_move_modifier = walk_speed if value == MoveMode.WALK else run_speed

func _ready():
	move_mode = MoveMode.WALK
	groundcast.target_position.y = -ride_height
	debug_path = debug_path
 
func _physics_process(delta: float) -> void:
	if nav.is_navigation_finished() and navigating:
		stop_navigation()
	
	apply_ride_force()
	
	if !navigating:
		return
		
	var next_path_position: Vector3 = nav.get_next_path_position()
	var direction := global_position.direction_to(next_path_position)
	var locomotion_input := speed_dir_curve.sample_baked(basis.z.dot(direction))
	
	apply_rotation(delta)
	apply_locomotion_force(locomotion_input)

func start_navigation(target_pos: Vector3) -> void:
	if Engine.is_editor_hint() and Input.is_key_pressed(KEY_SHIFT):
		global_position = target_pos
		return
	nav.target_position = target_pos
	navigating = true

func stop_navigation():
	navigating = false
	
func apply_ride_force() -> void:
	groundcast.force_raycast_update()
	if groundcast.is_colliding():
		var ground_position: Vector3 = groundcast.get_collision_point()
		var ground_dist : float = ground_position.distance_to(groundcast.global_position)
		var ray_dir_vel_dot := Vector3.DOWN.dot(linear_velocity)
		var x := ground_dist - ride_height
		var spring_force := (x * ride_spring_strength) - (ray_dir_vel_dot * ride_spring_damper)
		apply_central_force(Vector3.DOWN * spring_force * mass)
		DebugDraw2D.set_text("ground_force", "%2.2f" % spring_force)
	else:
		DebugDraw2D.set_text("ground_force", "not grounded")

func apply_locomotion_force(locomotion_input: float) -> void:
	var ground_vel: Vector3 = Vector3(linear_velocity.x, 0, linear_velocity.z)
	var goal_vel: Vector3 = basis.z * locomotion_input * _move_modifier
	var vel_dot: float = goal_vel.normalized().dot(ground_vel.normalized())
	var accel := acceleration_dir_factor.sample_baked(vel_dot) * acceleration
	goal_velocity = goal_velocity.move_toward(ground_vel + goal_vel, accel * (1. / Engine.physics_ticks_per_second))
	goal_velocity *= backward_walk_speed_modifier if locomotion_input < 0 else 1.
	var needed_accel := (goal_vel - ground_vel) / (1.0 / Engine.physics_ticks_per_second)
	var max_accel := acceleration_dir_factor.sample_baked(vel_dot) * max_acceleration
	needed_accel = needed_accel.limit_length(max_accel)
	apply_central_force(needed_accel * mass)

func apply_rotation(delta: float):
	# Smooth rotation towards target (Y-axis rotation)
	var direction = (nav.get_next_path_position() - global_transform.origin).normalized()
	var target_angle = Vector3.BACK.signed_angle_to(direction, basis.y)
	var smoothed_rotation = lerp_angle(rotation.y, target_angle, rotate_speed * delta)
	rotation.y = smoothed_rotation

func calculate_avoidance() -> Vector3:
	var avoidance_force: Vector3 = Vector3.ZERO
	return avoidance_force
