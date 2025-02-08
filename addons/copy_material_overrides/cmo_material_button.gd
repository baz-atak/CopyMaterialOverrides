@tool
extends Button


func _get_drag_data(at_position: Vector2) -> Variant:
	var parent = get_parent()
	if parent and parent.has_method("_get_drag_data"):
		return parent._get_drag_data(at_position)
	return null

func _can_drop_data(at_position: Vector2, data: Variant) -> bool:
	var parent = get_parent()
	if parent and parent.has_method("_can_drop_data"):
		return parent._can_drop_data(at_position, data)
	return false

func _drop_data(at_position: Vector2, data: Variant) -> void:
	var parent = get_parent()
	if parent and parent.has_method("_drop_data"):
		return parent._drop_data(at_position, data)
