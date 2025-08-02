@tool
extends Path3D

@export_tool_button("Spread Children Along Path")
var update_button: Callable = update_children

func _on_child_entered_tree(node: Node) -> void:
	if Engine.is_editor_hint():
		update_children()

func _on_child_exiting_tree(node: Node) -> void:
	if Engine.is_editor_hint():
		update_children()

func update_children():
	var follow_nodes: Array = get_children().filter(func(e): return e is PathFollow3D).map(func(e): return e as PathFollow3D)
	if curve.get_baked_length() == 0:
		printerr("Curve has a length of 0, returning without moving children")
		return
	var i := 0.0
	for follow: PathFollow3D in follow_nodes:
		var dist := curve.get_baked_length()
		var pos: float = dist * (i / len(follow_nodes))
		follow.progress = pos
		i += 1
