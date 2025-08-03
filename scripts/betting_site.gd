class_name BettingSite extends Node

@export var starting_balance: float = 500
var account_balance: float
var chosen_horse: StringName
var bet: float
const WIN_V_2 = preload("res://sounds/win_v2.mp3")

signal betting_locked

func _ready() -> void:
	account_balance = starting_balance
	$GUIPanel3D/SubViewport/GUI.set_account_balance(account_balance)

func initialize(horses: Array[HorseData]):
	$GUIPanel3D/SubViewport/GUI.bet_placed.connect(_on_gui_bet_placed)
	$GUIPanel3D/SubViewport/GUI.initialize(horses)

func resolve_race(placements: Array[HorseData]):
	for horse in placements:
		if horse.horse_name == chosen_horse:
			account_balance += bet * horse.odds
			$AudioStreamPlayer3D.stream = WIN_V_2
			$AudioStreamPlayer3D.play()
			return

func _on_gui_bet_placed(amount: float) -> void:
	account_balance -= amount
	betting_locked.emit()
	$GUIPanel3D/SubViewport/GUI.set_account_balance(account_balance)
