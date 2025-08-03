extends Node3D

var horses: Array[HorseController3D]
var horse_data: Dictionary[StringName, HorseData]
var selected_horse: HorseController3D
var spawn_points: Array[Node3D]
var race_active: bool = false
var last_standings: Array[HorseController3D]
var placements: Array[HorseData]
var names: Array[String]
var ready_for_cheer: bool = false
@onready var progress_tracker: PhantomCamera3D = %ProgressTracker
@onready var race_path: Path3D = $RacePath
@onready var announcer := $Camera3D/AudioStreamPlayer
@onready var crowd := $Camera3D/AudioStreamPlayer2

var announcer_track_index := 0
var announcer_tracks: Array[AudioStream] = [
	preload("res://sounds/announcer1.mp3"),
]
var cheer_track_index := 0
var cheer_tracks: Array[AudioStream] = [
	preload("res://sounds/cheer1.mp3"),
	preload("res://sounds/cheer2.mp3"),
	preload("res://sounds/cheer3.mp3"),
	preload("res://sounds/cheer4.mp3"),
	preload("res://sounds/cheer5.mp3"),
	preload("res://sounds/cheer6.mp3"),
	preload("res://sounds/cheer7.mp3"),
	preload("res://sounds/cheer8.mp3")
]

signal standings_changed(new_standings: Array[HorseData])
signal race_progressed(progress_ratio: float)
signal race_finished(placements: Array[HorseData])

func _ready() -> void:
	horses.assign(get_children().filter(func(e): return e is HorseController3D).map(func(e): return e as HorseController3D))
	spawn_points.assign($Spawns.get_children())
	names.assign(preload("res://scripts/horse_names_data.json").data.names)
	reset()
	
func reset():
	cheer_tracks.shuffle()
	last_standings.clear()
	placements.clear()
	horses.shuffle()
	var i := 0
	for horse in horses:
		horse.global_position = spawn_points[i].global_position
		horse_data[horse.name] = HorseData.new()\
		.with_name(names.pick_random().to_upper().trim_suffix(" "))\
		.with_number(5 * (i + 1) + randi() % 4)\
		.with_odds(randf_range(3, 20))\
		.with_color(Color.from_hsv(1 / 8.0 * (i + 1), .8, randf_range(.5, .7)))
		horse.initialize(horse_data[horse.name])
		i += 1
	var top6 = horses.slice(0, 6)
	var new_standings: Array[HorseData]
	new_standings.assign(top6.map(func(h): return horse_data[h.name]))
	standings_changed.emit(new_standings)
	announcer.volume_db = 0
	start_sequence()
	

func start_sequence() -> void:
	$CanvasLayer/RaceStartUi.visible = true
	%StartTimer.start()
	announcer.stream = announcer_tracks[announcer_track_index]
	announcer_track_index += 1
	announcer_track_index %= len(announcer_tracks)
	announcer.play()
	await %StartTimer.timeout
	ready_for_cheer = true
	$CanvasLayer/RaceStartUi.visible = false
	race_active = true
	await get_tree().create_timer(8).timeout
	$CanvasLayer/RaceUi.visible = true

func update_standings() -> void:
	var order: Array[HorseController3D]
	order.assign(horses)
	order.sort_custom(func(a, b): return a.nav.distance_to_target() < b.nav.distance_to_target())
	progress_tracker.follow_target = order[0]
	$LeadCamera.follow_target = order[0]
	var offset = race_path.curve.get_closest_offset(race_path.to_local(progress_tracker.global_position))
	var ratio = offset / race_path.curve.get_baked_length()
	race_progressed.emit(ratio)
	
	if last_standings != order:
		var top6 = order.slice(0, 6)
		var new_standings: Array[HorseData]
		new_standings.assign(top6.map(func(h): return horse_data[h.name]))
		standings_changed.emit(new_standings)

func _process(delta: float) -> void:
	if !race_active:
		return
	update_standings()

func _on_finish_line_body_entered(body: Node3D) -> void:
	var horse := body as HorseController3D
	if !horse:
		return
	if placements.is_empty():
		end_sequence()
	placements.append(horse_data[horse.name])
	race_active = false

func end_sequence():
	var wait_timer := get_tree().create_timer(8)
	while wait_timer.time_left > 0 and len(placements) < 8:
		await get_tree().physics_frame
	race_finished.emit(placements)
	fade_out(announcer)

func _on_bet_placed(horse: StringName) -> void:
	var index := horse_data.values().find_custom(func(hd): return hd.horse_name == horse)
	selected_horse = horse_data.find_key(horse_data.values()[index])
	start_sequence()

func fade_out(player: AudioStreamPlayer) -> void:
	const STEP = 0.01
	while player.volume_linear > STEP:
		player.volume_linear -= STEP
		await get_tree().physics_frame
	player.stop()

func _on_standings_changed(new_standings: Array[HorseData]) -> void:
	if !ready_for_cheer:
		return
	if new_standings.slice(0, 3) == last_standings.map(func(h): return horse_data[h.horse_name]).slice(0, 3):
		return
	crowd.stream = cheer_tracks[cheer_track_index]
	cheer_track_index += 1
	cheer_track_index %= len(cheer_tracks)
	crowd.play()
	ready_for_cheer = false
	get_tree().create_timer(crowd.stream.get_length()).timeout.connect(func(): ready_for_cheer = true)


func _on_room_encouraged() -> void:
	pass # Replace with function body.
