extends Node3D

var betting

signal bet_placed(horse: StringName)
signal encouraged

func _ready() -> void:
	betting = $Room/SofaCaddy/Laptop

func _on_race_track_race_finished(placements: Array[HorseData]) -> void:
	betting.resolve_race(placements)

func _on_betting_locked() -> void:
	bet_placed.emit(betting.chosen_horse)

func _on_hand_encouragement_sent() -> void:
	encouraged.emit()
