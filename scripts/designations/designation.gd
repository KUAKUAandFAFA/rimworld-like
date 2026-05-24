class_name Designation
extends RefCounted

var designation_type := ""
var target_cell := Vector2i.ZERO
var label := ""


func _init(new_type: String = "", new_target_cell: Vector2i = Vector2i.ZERO, new_label: String = "") -> void:
	designation_type = new_type
	target_cell = new_target_cell
	label = new_label


func display_label() -> String:
	if label != "":
		return label

	return designation_type.capitalize()


func debug_summary() -> String:
	return "%s at (%d, %d)" % [
		display_label(),
		target_cell.x,
		target_cell.y,
	]
