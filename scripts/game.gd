extends Node3D

var track
func _ready() -> void:
	get_tree().root.find_child("RaceTrack")
