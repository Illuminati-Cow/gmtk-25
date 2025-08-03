extends Node3D

@onready var music_player: AudioStreamPlayer3D = $AudioStreamPlayer3D
@onready var station_player: AudioStreamPlayer3D = $AudioStreamPlayer3D2

var playlist_index := 0
var playlist: Array[AudioStream] = [
	preload("res://sounds/Hayride.mp3")
]


func _on_room_game_started() -> void:
	music_player.finished.connect(_on_song_finished)
	_on_song_finished()


func _on_song_finished():
	music_player.stream = playlist[playlist_index % len(playlist)]
	playlist_index += 1
	music_player.play()


func fade_out(player: AudioStreamPlayer) -> void:
	const STEP = 0.01
	while player.volume_linear > STEP:
		player.volume_linear -= STEP
		await get_tree().physics_frame
	player.stop()
