class_name BettingSite extends Node

@export var starting_balance: float = 500
var account_balance: float
var chosen_horse: HorseData
var bet: float
const WIN_V_2 = preload("res://sounds/win_v2.mp3")
const LOSE = preload("res://sounds/lose.mp3")

signal betting_locked

func _ready() -> void:
	account_balance = starting_balance
	$GUIPanel3D/SubViewport/GUI.set_account_balance(account_balance)
	$GUIPanel3D/SubViewport/GUI.bet_placed.connect(_on_gui_bet_placed)

func initialize(horses: Array[HorseData]):
	$GUIPanel3D/SubViewport/GUI.initialize(horses)

func resolve_race(placements: Array[HorseData]):
	placements = placements.slice(0, 3)
	var win_mult = 1.0
	for horse in placements:
		if horse.horse_name == chosen_horse.horse_name:
			account_balance += bet * horse.odds * win_mult
			$AudioStreamPlayer3D.stream = WIN_V_2
			$AudioStreamPlayer3D.play()
			$GUIPanel3D/SubViewport/GUI.set_account_balance(account_balance)
			return
		win_mult -= 0.33
	$GUIPanel3D/SubViewport/GUI.set_account_balance(account_balance)
	$AudioStreamPlayer3D.stream = LOSE
	$AudioStreamPlayer3D.play()

func _on_gui_bet_placed(amount: float, horse: HorseData) -> void:
	chosen_horse = horse
	account_balance -= amount
	bet = amount
	betting_locked.emit()
	$GUIPanel3D/SubViewport/GUI.set_account_balance(account_balance)
