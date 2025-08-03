extends Control

signal bet_placed(amount: float)

var old_bet
var horse_entries: Array
var button_group := preload("res://scenes/elements/betting_button_group.tres")
@onready var bet_field := %BetField

func _ready() -> void:
	horse_entries = %HorseEntries.get_children()

func _on_bet_button_pressed() -> void:
	if !button_group.get_pressed_button() or bet_field.value == 0:
		$DeclinePlayer.play()
		return
	%CancelPanel.visible = true
	%SubmitPlayer.play()

func set_account_balance(amount: float):
	%AccountBalance.value = amount

func initialize(horses: Array[HorseData]):
	var i := 0
	for entry: Control in horse_entries:
		var data := horses[i]
		entry.get_node(^"HBoxContainer/Number").text = "%d" % data.number
		entry.get_node(^"HBoxContainer/Odds").text = "%d-1" % data.odds
		entry.get_node(^"HBoxContainer/Name").text = data.horse_name
		entry.get_node(^"HBoxContainer/JockeyName").text = "Horace Ryder".to_upper()
		entry.get_node(^"HBoxContainer/Number/ColorRect").color = data.color
		i += 1
	old_bet = bet_field.value
	bet_field.max_value = %AccountBalance.value
	bet_field.value = min(bet_field.max_value, 100)
	%InProgressScreen.visible = false

func _on_bet_field_value_changed(value: float) -> void:
	if value > old_bet:
		$Panel/IncreasePlayer.play()
	else:
		$Panel/DecreasePlayer.play()
	old_bet = value
	
func _on_cancel_popup_confirmed() -> void:
	bet_placed.emit(bet_field.value)
	%ConfirmPlayer.play()
	%InProgressScreen.visible = true
