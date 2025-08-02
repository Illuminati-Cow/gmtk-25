extends Node3D

var betting

signal bet_placed

func _ready() -> void:
	betting = $Room/SofaCaddy/Laptop

func _on_race_track_race_finished(placements: Array[HorseData]) -> void:
	betting.resolve_race(placements)

func _on_betting_locked() -> void:
	bet_placed.emit()
