class_name ColonyHud
extends CanvasLayer

@onready var _summary_label: Label = %SummaryLabel

var _status_text := "Idle"
var _stockpile_snapshot: Dictionary = {}


func _ready() -> void:
	_refresh()


func set_status(text: String) -> void:
	_status_text = text
	_refresh()


func set_stockpile_snapshot(snapshot: Dictionary) -> void:
	_stockpile_snapshot = snapshot.duplicate(true)
	_refresh()


func _refresh() -> void:
	if _summary_label == null:
		return

	_summary_label.text = "Colony Sample\nStatus: %s\n%s" % [
		_status_text,
		_format_stockpile(),
	]


func _format_stockpile() -> String:
	if _stockpile_snapshot.is_empty():
		return "No stockpile"

	var entries := PackedStringArray()
	var item_ids := _stockpile_snapshot.keys()
	item_ids.sort()

	for raw_item_id in item_ids:
		var item_id := String(raw_item_id)
		var item_data: Dictionary = _stockpile_snapshot[item_id]
		entries.append("%s: %d" % [
			String(item_data.get("label", item_id.capitalize())),
			int(item_data.get("amount", 0)),
		])

	return "    ".join(entries)
