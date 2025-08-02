extends Node

@export var starting_balance: float = 1000
var account_balance: float
var chosen_horse: StringName
var bet: float

signal betting_locked

func _ready() -> void:
	account_balance = starting_balance

func resolve_race(placements: Array[HorseData]):
	for horse in placements:
		if horse.horse_name == chosen_horse:
			account_balance = bet * horse.odds
			return
