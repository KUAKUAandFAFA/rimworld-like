class_name StockpileZoneSystem
extends Node2D

signal zones_changed(snapshot: Dictionary)

const DEFAULT_ZONE_ID := "stockpile_1"
const DEFAULT_ZONE_NAME := "Stockpile 1"
const DEFAULT_PRIORITY := 1

@export var cell_size := 32

var _zones: Dictionary = {}
var _cell_index: Dictionary = {}
var _item_defs: Dictionary = {}


func configure(new_cell_size: int) -> void:
	cell_size = maxi(1, new_cell_size)
	queue_redraw()


func register_item(item_def: ItemDef) -> void:
	if item_def == null or item_def.id == "":
		return

	_item_defs[item_def.id] = item_def
	for zone in _sorted_zones():
		zone.allow_item(item_def.id)

	_emit_changed()


func toggle_default_zone_cell(cell: Vector2i) -> bool:
	var zone := ensure_default_zone()
	var added := false
	if zone.has_cell(cell):
		zone.remove_cell(cell)
		_cell_index.erase(cell)
	else:
		_remove_cell_from_existing_zone(cell)
		zone.add_cell(cell)
		_cell_index[cell] = zone.id
		added = true

	_emit_changed()
	return added


func ensure_default_zone() -> StockpileZone:
	var zone := get_zone(DEFAULT_ZONE_ID)
	if zone != null:
		return zone

	zone = StockpileZone.new(DEFAULT_ZONE_ID, DEFAULT_ZONE_NAME, DEFAULT_PRIORITY)
	_allow_registered_items(zone)
	_zones[zone.id] = zone
	_emit_changed()
	return zone


func get_zone(zone_id: String) -> StockpileZone:
	return _zones.get(zone_id, null) as StockpileZone


func get_zone_at(cell: Vector2i) -> StockpileZone:
	var zone_id := String(_cell_index.get(cell, ""))
	if zone_id == "":
		return null

	return get_zone(zone_id)


func get_cell_debug_text(cell: Vector2i) -> String:
	var zone := get_zone_at(cell)
	if zone == null:
		return "None"

	return zone.cell_debug_text(cell, _item_labels())


func get_debug_snapshot() -> Dictionary:
	return {
		"count": _zones.size(),
		"zones": _zone_debug_lines(),
		"save_data": to_save_data(),
	}


func to_save_data() -> Array[Dictionary]:
	var save_data: Array[Dictionary] = []
	for zone in _sorted_zones():
		save_data.append(zone.to_save_dict())

	return save_data


func _remove_cell_from_existing_zone(cell: Vector2i) -> void:
	var existing_zone := get_zone_at(cell)
	if existing_zone != null:
		existing_zone.remove_cell(cell)

	_cell_index.erase(cell)


func _allow_registered_items(zone: StockpileZone) -> void:
	for raw_item_id in _item_defs.keys():
		zone.allow_item(String(raw_item_id))


func _zone_debug_lines() -> PackedStringArray:
	var lines := PackedStringArray()
	for zone in _sorted_zones():
		lines.append(zone.debug_summary(_item_labels()))

	return lines


func _sorted_zones() -> Array[StockpileZone]:
	var zones: Array[StockpileZone] = []
	var zone_ids := PackedStringArray()
	for raw_zone_id in _zones.keys():
		zone_ids.append(String(raw_zone_id))

	zone_ids.sort()
	for zone_id in zone_ids:
		var zone := get_zone(zone_id)
		if zone != null:
			zones.append(zone)

	return zones


func _item_labels() -> Dictionary:
	var labels := {}
	for raw_item_id in _item_defs.keys():
		var item_id := String(raw_item_id)
		var item_def := _item_defs[item_id] as ItemDef
		labels[item_id] = item_def.label() if item_def != null else item_id.capitalize()

	return labels


func _emit_changed() -> void:
	zones_changed.emit(get_debug_snapshot())
	queue_redraw()


func _draw() -> void:
	for zone in _sorted_zones():
		for cell in zone.cells:
			var rect := Rect2(Vector2(cell.x * cell_size, cell.y * cell_size), Vector2(cell_size, cell_size))
			draw_rect(rect.grow(-2.0), Color(0.20, 0.48, 0.88, 0.24))
			draw_rect(rect.grow(-2.0), Color(0.45, 0.78, 1.0, 0.8), false, 2.0)
