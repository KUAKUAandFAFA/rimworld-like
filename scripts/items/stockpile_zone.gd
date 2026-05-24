class_name StockpileZone
extends RefCounted

var id := ""
var display_name := ""
var priority := 1
var cells: Array[Vector2i] = []
var allowed_item_ids := PackedStringArray()


func _init(new_id: String = "", new_display_name: String = "", new_priority: int = 1) -> void:
	id = new_id
	display_name = new_display_name
	priority = new_priority


func add_cell(cell: Vector2i) -> bool:
	if cells.has(cell):
		return false

	cells.append(cell)
	return true


func remove_cell(cell: Vector2i) -> bool:
	if not cells.has(cell):
		return false

	cells.erase(cell)
	return true


func has_cell(cell: Vector2i) -> bool:
	return cells.has(cell)


func allow_item(item_id: String) -> bool:
	if item_id == "" or allowed_item_ids.has(item_id):
		return false

	allowed_item_ids.append(item_id)
	allowed_item_ids.sort()
	return true


func allows_item(item_def: ItemDef) -> bool:
	if item_def == null:
		return false

	return allowed_item_ids.has(item_def.id)


func cell_count() -> int:
	return cells.size()


func label() -> String:
	if display_name != "":
		return display_name

	return id.capitalize()


func debug_summary(item_labels: Dictionary = {}) -> String:
	return "%s priority %d cells %d allowed %s" % [
		label(),
		priority,
		cell_count(),
		_allowed_items_debug_text(item_labels),
	]


func cell_debug_text(cell: Vector2i, item_labels: Dictionary = {}) -> String:
	if not has_cell(cell):
		return "None"

	return "%s priority %d allowed %s" % [
		label(),
		priority,
		_allowed_items_debug_text(item_labels),
	]


func to_save_dict() -> Dictionary:
	var cell_data: Array[Dictionary] = []
	for cell in cells:
		cell_data.append({
			"x": cell.x,
			"y": cell.y,
		})

	return {
		"id": id,
		"display_name": display_name,
		"priority": priority,
		"cells": cell_data,
		"allowed_item_ids": Array(allowed_item_ids),
	}


func _allowed_items_debug_text(item_labels: Dictionary) -> String:
	if allowed_item_ids.is_empty():
		return "none"

	var labels := PackedStringArray()
	for item_id in allowed_item_ids:
		labels.append(String(item_labels.get(item_id, item_id.capitalize())))

	return ", ".join(labels)
