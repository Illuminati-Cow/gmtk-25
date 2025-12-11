extends Node3D

@onready var betting: BettingSite = $Room/SofaCaddy/Laptop

signal bet_placed(horse: HorseData)
signal encouraged
signal game_started

func _ready() -> void:
	await get_tree().create_timer(0.1).timeout
	game_started.emit()

func _on_race_track_race_finished(placements: Array[HorseData]) -> void:
	betting.resolve_race(placements)

func _on_betting_locked() -> void:
	bet_placed.emit(betting.chosen_horse)

func _on_hand_encouragement_sent() -> void:
	encouraged.emit()

func _on_race_track_race_initialized(horses: Array[HorseData]) -> void:
	betting.initialize(horses)
