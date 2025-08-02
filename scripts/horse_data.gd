class_name HorseData extends Resource

@export var horse_name: StringName
@export var odds: float
@export var number: int
@export var color: Color

func with_name(name: StringName) -> HorseData:
	horse_name = name
	return self

func with_odds(new_odds: float) -> HorseData:
	odds = new_odds
	return self

func with_number(new_number: int) -> HorseData:
	number = new_number
	return self

func with_color(new_color: Color) -> HorseData:
	color = new_color
	return self

func _to_string() -> String:
	return "%d %s %s %d-1 (%f)" % [number, horse_name, color, odds, odds]
