class_name HorseController3D extends RigidBody3D

enum MoveMode
{
	WALK,
	RUN,
}


@export_category("Movement")
@export_range(0, 10, 0.25) var base_walk_speed: float = 3
@export_range(0, 10, 0.25) var base_run_speed: float = 8
@export var acceleration: float = 1
@export var max_acceleration: float = 1
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
@export var movement_modifier: float = 1

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
@onready var model := $Model

var goal_velocity: Vector3
var navigating: bool = false
var _move_mode_modifier: float = 1
var move_mode: MoveMode:
	get:
		return move_mode
	set(value):
		move_mode = value
		_move_mode_modifier = base_walk_speed if value == MoveMode.WALK else base_run_speed

func _ready():
	move_mode = MoveMode.WALK
	groundcast.target_position.y = -ride_height
	debug_path = debug_path
	%StartTimer.timeout.connect(_on_start_timer_timeout)
 
func _physics_process(delta: float) -> void:
	if nav.is_navigation_finished() and navigating:
		stop_navigation()
	
	#apply_ride_force()
	
	if !navigating:
		calculate_goal_velocity(Vector3.ZERO)
		return
		
	var next_path_position: Vector3 = nav.get_next_path_position()
	var direction := global_position.direction_to(next_path_position)
	#var locomotion_input := speed_dir_curve.sample_baked(basis.z.dot(direction))
	
	apply_rotation(delta)
	calculate_goal_velocity(direction)

func start_navigation(target_pos: Vector3) -> void:
	if Engine.is_editor_hint() and Input.is_key_pressed(KEY_SHIFT):
		global_position = target_pos
		return
	nav.target_position = target_pos
	navigating = true
	$AnimationPlayer.play(&"Run")
	
func stop_navigation():
	navigating = false
	$AnimationPlayer.play(&"RESET")
	
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

func calculate_goal_velocity(direction: Vector3) -> void:
	var ground_vel: Vector3 = Vector3(linear_velocity.x, 0, linear_velocity.z)
	var goal_vel: Vector3 = direction.normalized() * _move_mode_modifier
	var vel_dot: float = goal_vel.normalized().dot(ground_vel.normalized())
	var accel := acceleration_dir_factor.sample_baked(vel_dot) * acceleration
	goal_velocity = goal_velocity.move_toward(ground_vel + goal_vel, accel * (1. / Engine.physics_ticks_per_second))
	nav.velocity = goal_velocity
	DebugDraw3D.draw_ray(global_position, goal_velocity.normalized(), goal_velocity.length(), Color.RED)
	if !nav.avoidance_enabled or nav.is_navigation_finished():
		var needed_accel := (goal_vel - ground_vel) / (1.0 / Engine.physics_ticks_per_second)
		var max_accel := acceleration_dir_factor.sample_baked(vel_dot) * max_acceleration
		needed_accel = needed_accel.limit_length(max_accel)
		apply_central_force(needed_accel * mass)
	#DebugDraw2D.set_text("velocity", "%.2f" % linear_velocity.length())
	#DebugDraw2D.set_text("needed_accel", "%.2f" % needed_accel.length())

func apply_rotation(delta: float):
	# Smooth rotation towards target (Y-axis rotation)
	#var direction = (nav.get_next_path_position() - global_transform.origin).normalized()
	var direction = goal_velocity.normalized()
	var target_angle = Vector3.BACK.signed_angle_to(direction, basis.y)
	var smoothed_rotation = lerp_angle(rotation.y, target_angle, rotate_speed * delta)
	rotation.y = smoothed_rotation
	var vel_dot := -basis.x.dot(linear_velocity.normalized())
	var horizontal_energy := clampf(sqrt(abs(linear_velocity.x)) / 3, 0, 1) * vel_dot
	DebugDraw2D.set_text("h_v", "%.2f" % horizontal_energy)
	model.rotation.x = lerp_angle(model.rotation.x, deg_to_rad(horizontal_energy * 45), rotate_speed * delta) 

func calculate_avoidance() -> Vector3:
	var avoidance_force: Vector3 = Vector3.ZERO
	return avoidance_force

func _on_start_timer_timeout() -> void:
	move_mode = MoveMode.RUN
	nav.avoidance_enabled = false
	start_navigation(%FinishLine.global_position)
	get_tree().create_timer(2).timeout.connect(func(): nav.avoidance_enabled = true)

func _on_navigation_agent_3d_velocity_computed(safe_velocity: Vector3) -> void:
	if nav.is_navigation_finished():
		return
	
	var ground_vel: Vector3 = Vector3(linear_velocity.x, 0, linear_velocity.z)
	var goal_vel: Vector3 = (safe_velocity + goal_velocity).limit_length(_move_mode_modifier)
	var vel_dot: float = goal_vel.normalized().dot(ground_vel.normalized())
	var accel := acceleration_dir_factor.sample_baked(vel_dot) * acceleration
	var needed_accel := (goal_vel - ground_vel) / (1.0 / Engine.physics_ticks_per_second)
	var max_accel := acceleration_dir_factor.sample_baked(vel_dot) * max_acceleration
	needed_accel = needed_accel.limit_length(max_accel)
	apply_central_force(needed_accel * mass)
	DebugDraw2D.set_text("velocity", ground_vel)
	DebugDraw3D.draw_ray(global_position, safe_velocity, needed_accel.length(), Color.GREEN)
