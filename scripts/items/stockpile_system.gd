class_name StockpileSystem
extends Node

signal stockpile_changed(snapshot: Dictionary)

var _amounts: Dictionary = {}
var _item_defs: Dictionary = {}


func register_item(item_def: ItemDef) -> void:
	if item_def == null or item_def.id == "":
		return

	var item_id := item_def.id
	_item_defs[item_id] = item_def
	if not _amounts.has(item_id):
		_amounts[item_id] = 0

	stockpile_changed.emit(get_snapshot())


func add_item(item_def: ItemDef, amount: int) -> void:
	if item_def == null or amount <= 0:
		return

	var item_id := item_def.id
	_item_defs[item_id] = item_def
	_amounts[item_id] = int(_amounts.get(item_id, 0)) + amount
	stockpile_changed.emit(get_snapshot())


func get_amount(item_id: String) -> int:
	return int(_amounts.get(item_id, 0))


func get_snapshot() -> Dictionary:
	var snapshot := {}
	for raw_item_id in _amounts.keys():
		var item_id := String(raw_item_id)
		var item_def: ItemDef = _item_defs.get(item_id, null)
		var label := item_id.capitalize()
		if item_def != null:
			label = item_def.label()

		snapshot[item_id] = {
			"label": label,
			"amount": int(_amounts[item_id]),
		}

	return snapshot
