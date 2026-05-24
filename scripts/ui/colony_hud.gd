class_name ColonyHud
extends CanvasLayer

signal command_mode_requested(mode: String)

@onready var _summary_label: Label = %SummaryLabel
@onready var _move_button: Button = %MoveButton
@onready var _harvest_button: Button = %HarvestButton
@onready var _cancel_button: Button = %CancelButton
@onready var _stockpile_button: Button = %StockpileButton

var _status_text := "Idle"
var _command_mode_label := "Move"
var _active_command_mode := CommandModeModel.MODE_MOVE
var _stockpile_snapshot: Dictionary = {}
var _mode_buttons: Dictionary = {}


func _ready() -> void:
	_mode_buttons = {
		CommandModeModel.MODE_MOVE: _move_button,
		CommandModeModel.MODE_HARVEST: _harvest_button,
		CommandModeModel.MODE_CANCEL: _cancel_button,
		CommandModeModel.MODE_STOCKPILE: _stockpile_button,
	}
	_connect_command_buttons()
	_refresh()


func set_status(text: String) -> void:
	_status_text = text
	_refresh()


func set_command_mode(mode: String, label: String) -> void:
	_active_command_mode = mode
	_command_mode_label = label
	_refresh_command_buttons()
	_refresh()


func set_stockpile_snapshot(snapshot: Dictionary) -> void:
	_stockpile_snapshot = snapshot.duplicate(true)
	_refresh()


func _refresh() -> void:
	if _summary_label == null:
		return

	_summary_label.text = "Colony Sample\nMode: %s\nStatus: %s\n%s" % [
		_command_mode_label,
		_status_text,
		_format_stockpile(),
	]

	_refresh_command_buttons()


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


func _connect_command_buttons() -> void:
	_connect_mode_button(_move_button, CommandModeModel.MODE_MOVE)
	_connect_mode_button(_harvest_button, CommandModeModel.MODE_HARVEST)
	_connect_mode_button(_cancel_button, CommandModeModel.MODE_CANCEL)
	_connect_mode_button(_stockpile_button, CommandModeModel.MODE_STOCKPILE)


func _connect_mode_button(button: Button, mode: String) -> void:
	if button == null:
		return

	var callback := _on_command_button_pressed.bind(mode)
	if not button.pressed.is_connected(callback):
		button.pressed.connect(callback)


func _on_command_button_pressed(mode: String) -> void:
	command_mode_requested.emit(mode)


func _refresh_command_buttons() -> void:
	for raw_mode in _mode_buttons.keys():
		var mode := String(raw_mode)
		var button := _mode_buttons[mode] as Button
		if button != null:
			button.set_pressed_no_signal(mode == _active_command_mode)
