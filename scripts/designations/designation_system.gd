class_name DesignationSystem
extends Node2D

signal designation_added(designation: Designation)
signal designation_removed(designation: Designation)
signal designations_changed

const TYPE_HARVEST := "harvest"
const TYPE_LABELS := {
	TYPE_HARVEST: "Harvest",
}

var grid: WorldGrid
var cell_size := 32

var _designations_by_cell: Dictionary = {}


func configure(new_grid: WorldGrid) -> void:
	grid = new_grid
	if grid != null:
		cell_size = grid.cell_size

	queue_redraw()


func add_designation(designation_type: String, target_cell: Vector2i) -> Designation:
	if designation_type == "":
		push_warning("DesignationSystem: ignored empty designation type")
		return null

	if has_designation(target_cell, designation_type):
		return get_designation_at(target_cell)

	var designation := Designation.new(designation_type, target_cell, get_designation_label(designation_type))
	_designations_by_cell[target_cell] = designation
	designation_added.emit(designation)
	designations_changed.emit()
	queue_redraw()
	return designation


func remove_designation(target_cell: Vector2i) -> bool:
	var designation := get_designation_at(target_cell)
	if designation == null:
		return false

	_designations_by_cell.erase(target_cell)
	designation_removed.emit(designation)
	designations_changed.emit()
	queue_redraw()
	return true


func has_designation(target_cell: Vector2i, designation_type: String = "") -> bool:
	var designation := get_designation_at(target_cell)
	if designation == null:
		return false

	return designation_type == "" or designation.designation_type == designation_type


func get_designation_at(target_cell: Vector2i) -> Designation:
	return _designations_by_cell.get(target_cell, null) as Designation


func get_designations() -> Array[Designation]:
	var designations: Array[Designation] = []
	for raw_designation in _designations_by_cell.values():
		var designation := raw_designation as Designation
		if designation != null:
			designations.append(designation)

	return designations


func get_designation_count() -> int:
	return _designations_by_cell.size()


func get_designation_label(designation_type: String) -> String:
	return String(TYPE_LABELS.get(designation_type, designation_type.capitalize()))


func get_debug_snapshot() -> Dictionary:
	var lines := PackedStringArray()
	for designation in get_designations():
		lines.append(designation.debug_summary())

	return {
		"count": get_designation_count(),
		"designations": lines,
	}


func _draw() -> void:
	for designation in get_designations():
		_draw_designation(designation)


func _draw_designation(designation: Designation) -> void:
	var rect := Rect2(
		Vector2(designation.target_cell.x * cell_size, designation.target_cell.y * cell_size),
		Vector2(cell_size, cell_size)
	)
	var color := _designation_color(designation.designation_type)

	draw_rect(rect.grow(-3.0), Color(color.r, color.g, color.b, 0.22))
	draw_rect(rect.grow(-3.0), color, false, 2.0)
	draw_line(rect.position + Vector2(6.0, 6.0), rect.end - Vector2(6.0, 6.0), color, 2.0, true)
	draw_line(Vector2(rect.end.x - 6.0, rect.position.y + 6.0), Vector2(rect.position.x + 6.0, rect.end.y - 6.0), color, 2.0, true)


func _designation_color(designation_type: String) -> Color:
	match designation_type:
		TYPE_HARVEST:
			return Color(0.95, 0.72, 0.22)
		_:
			return Color(0.72, 0.82, 0.95)
