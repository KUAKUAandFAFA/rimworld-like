class_name CommandModeModel
extends Node

signal mode_changed(mode: String, label: String)

const MODE_MOVE := "move"
const MODE_HARVEST := "harvest"
const MODE_CANCEL := "cancel"

const MODES := [
	MODE_MOVE,
	MODE_HARVEST,
	MODE_CANCEL,
]

const MODE_LABELS := {
	MODE_MOVE: "Move",
	MODE_HARVEST: "Harvest",
	MODE_CANCEL: "Cancel",
}

@export_enum("move", "harvest", "cancel") var default_mode := MODE_MOVE

var _active_mode := MODE_MOVE


func _ready() -> void:
	set_mode(default_mode)


func set_mode(mode: String) -> void:
	if not is_valid_mode(mode):
		push_warning("CommandModeModel: ignored unknown command mode %s" % mode)
		return

	if _active_mode == mode:
		mode_changed.emit(_active_mode, get_mode_label(_active_mode))
		return

	_active_mode = mode
	mode_changed.emit(_active_mode, get_mode_label(_active_mode))


func get_mode() -> String:
	return _active_mode


func get_mode_label(mode: String = "") -> String:
	var mode_to_label := _active_mode if mode == "" else mode
	return String(MODE_LABELS.get(mode_to_label, mode_to_label.capitalize()))


func get_modes() -> PackedStringArray:
	var modes := PackedStringArray()
	for mode in MODES:
		modes.append(String(mode))

	return modes


func is_valid_mode(mode: String) -> bool:
	return MODES.has(mode)
