extends Node3D

@onready var music_player: AudioStreamPlayer3D = $AudioStreamPlayer3D
@onready var station_player: AudioStreamPlayer3D = $AudioStreamPlayer3D2

var playlist_index := 0
var playlist: Array[AudioStream] = [
	preload("res://sounds/Hayride.mp3"),
	preload("res://sounds/Neighsayer.mp3"),
	preload("res://sounds/Hot2Trot.mp3"),
	preload("res://sounds/FreeSpirit.mp3"),
	preload("res://sounds/TheFarm.mp3"), 
	preload("res://sounds/EasyDoesIt.mp3")
]

var announcer_track_index := 0
var announcer_tracks: Array[AudioStream] = [
	preload("res://sounds/horsefm1.mp3"),
	preload("res://sounds/horsefm2.mp3"),
	preload("res://sounds/horsefm3.mp3")
]


func _on_room_game_started() -> void:
	playlist.shuffle()
	announcer_tracks.shuffle()
	music_player.finished.connect(_on_song_finished)
	_on_song_finished()


func _on_song_finished():
	music_player.stream = playlist[playlist_index % len(playlist)]
	playlist_index += 1
	station_player.stream = announcer_tracks[announcer_track_index % len(announcer_tracks)]
	announcer_track_index += 1
	station_player.play()
	await station_player.finished
	music_player.play()


func fade_out(player: AudioStreamPlayer) -> void:
	const STEP = 0.01
	while player.volume_linear > STEP:
		player.volume_linear -= STEP
		await get_tree().physics_frame
	player.stop()
