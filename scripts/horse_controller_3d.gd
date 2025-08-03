class_name HorseController3D extends RigidBody3D

enum MoveMode
{
	WALK,
	RUN,
}


@export_category("Racing Stats")
@export var energy := 10.0

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
@onready var model := $HorseMesh
@onready var anim_tree := $AnimationTree

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
	var helmet_mat: StandardMaterial3D = $HorseMesh/Armature/Skeleton3D/person.get_active_material(3)
	$HorseMesh/Armature/Skeleton3D/person.set_surface_override_material(3, helmet_mat.duplicate())
	var saddle_trim_mat: StandardMaterial3D = $HorseMesh/Armature/Skeleton3D/saddle/saddle.get_active_material(0)
	$HorseMesh/Armature/Skeleton3D/saddle/saddle.set_surface_override_material(0, saddle_trim_mat.duplicate())
	var shirt_mat: StandardMaterial3D = $HorseMesh/Armature/Skeleton3D/person.get_active_material(2)
	$HorseMesh/Armature/Skeleton3D/person.set_surface_override_material(2, shirt_mat.duplicate())
	var horse_mat: StandardMaterial3D = $HorseMesh/Armature/Skeleton3D/horse.get_active_material(1)
	$HorseMesh/Armature/Skeleton3D/horse.set_surface_override_material(1, horse_mat.duplicate())
 
func reset() -> void:
	linear_velocity = Vector3.ZERO
	set_physics_process(false)
	stop_navigation()
	anim_tree.set(&"parameters/RunBlend/blend_amount", 0)

func initialize(data: HorseData) -> void:
	var texture: GradientTexture2D = $SubViewport/Panel/TextureRect.texture
	texture.gradient = texture.gradient.duplicate()
	print(texture.gradient.colors)
	texture.gradient.set_color(0, data.color)
	texture.gradient.set_color(1, data.color)
	print(texture.gradient.colors)
	$SubViewport/Panel/Label.text = "%d" % data.number
	var saddle_trim_mat: StandardMaterial3D = $HorseMesh/Armature/Skeleton3D/saddle/saddle.get_surface_override_material(0)
	saddle_trim_mat.albedo_color = data.color
	var helmet_mat: StandardMaterial3D = $HorseMesh/Armature/Skeleton3D/person.get_surface_override_material(3)
	helmet_mat.albedo_color = data.color.darkened(0.2)
	var shirt_mat: StandardMaterial3D = $HorseMesh/Armature/Skeleton3D/person.get_surface_override_material(2)
	var horse_mat: StandardMaterial3D = $HorseMesh/Armature/Skeleton3D/horse.get_surface_override_material(1)
	horse_mat.albedo_color = get_random_horse_color()
	shirt_mat.albedo_color = data.color

func _physics_process(delta: float) -> void:
	if nav.is_navigation_finished() and navigating:
		stop_navigation()
	
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


func stop_navigation():
	navigating = false


func calculate_goal_velocity(direction: Vector3) -> void:
	var ground_vel: Vector3 = Vector3(linear_velocity.x, 0, linear_velocity.z)
	anim_tree.set(&"parameters/RunBlend/blend_amount", ground_vel.length() / base_run_speed)
	var goal_vel: Vector3 = direction.normalized() * _move_mode_modifier
	var vel_dot: float = goal_vel.normalized().dot(ground_vel.normalized())
	var accel := acceleration_dir_factor.sample_baked(vel_dot) * acceleration
	goal_velocity = goal_velocity.move_toward(ground_vel + goal_vel, accel * (1. / Engine.physics_ticks_per_second))
	nav.velocity = goal_velocity
	#DebugDraw3D.draw_ray(global_position, goal_velocity.normalized(), goal_velocity.length(), Color.RED)
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
	var horizontal_energy := clampf(sqrt(abs(linear_velocity.x)) / 2, 0, 1) * vel_dot
	#DebugDraw2D.set_text("h_v", "%.2f" % horizontal_energy)
	model.rotation.x = lerp_angle(model.rotation.x, deg_to_rad(horizontal_energy * 45), rotate_speed * delta) 

func _on_start_timer_timeout() -> void:
	move_mode = MoveMode.RUN
	nav.avoidance_enabled = false
	set_physics_process(true)
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
	#DebugDraw2D.set_text("velocity", ground_vel)
	#DebugDraw3D.draw_ray(global_position, safe_velocity, needed_accel.length(), Color.GREEN)

func get_random_horse_color():
	var h: float
	var s: float
	var v: float

	# Randomly decide between a chromatic or achromatic horse.
	var type_roll = randf()

	if type_roll < 0.9:
		h = randf_range(0.04, 0.09)
		s = randf_range(0.35, 0.9)
		v = randf_range(0.15, 0.7)
	else:
		h = 0.0
		s = randf_range(0.0, 0.15)
		v = randf_range(0.05, 0.95)

	return Color.from_hsv(h, s, v)
