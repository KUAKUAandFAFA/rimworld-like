class_name PlayerInputController
extends Node2D

signal primary_cell_clicked(cell: Vector2i)
signal command_mode_requested(mode: String)
signal camera_pan_requested(direction: Vector2, delta: float)
signal camera_zoom_requested(amount: float)

const ACTION_COMMAND_MOVE := "command_mode_move"
const ACTION_COMMAND_HARVEST := "command_mode_harvest"
const ACTION_COMMAND_CANCEL := "command_mode_cancel"
const ACTION_COMMAND_STOCKPILE := "command_mode_stockpile"

var grid: WorldGrid


func _ready() -> void:
	_ensure_key_action(ACTION_COMMAND_MOVE, KEY_1)
	_ensure_key_action(ACTION_COMMAND_HARVEST, KEY_2)
	_ensure_key_action(ACTION_COMMAND_CANCEL, KEY_3)
	_ensure_key_action(ACTION_COMMAND_STOCKPILE, KEY_4)


func configure(new_grid: WorldGrid) -> void:
	grid = new_grid


func _process(delta: float) -> void:
	var direction := Vector2.ZERO

	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
		direction.x -= 1.0
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
		direction.x += 1.0
	if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
		direction.y -= 1.0
	if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
		direction.y += 1.0

	if direction != Vector2.ZERO:
		camera_pan_requested.emit(direction.normalized(), delta)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(ACTION_COMMAND_MOVE):
		command_mode_requested.emit(CommandModeModel.MODE_MOVE)
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed(ACTION_COMMAND_HARVEST):
		command_mode_requested.emit(CommandModeModel.MODE_HARVEST)
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed(ACTION_COMMAND_CANCEL):
		command_mode_requested.emit(CommandModeModel.MODE_CANCEL)
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed(ACTION_COMMAND_STOCKPILE):
		command_mode_requested.emit(CommandModeModel.MODE_STOCKPILE)
		get_viewport().set_input_as_handled()
		return

	if grid == null:
		return

	if event is not InputEventMouseButton:
		return

	var mouse_event := event as InputEventMouseButton
	if not mouse_event.pressed:
		return

	if mouse_event.button_index == MOUSE_BUTTON_LEFT:
		primary_cell_clicked.emit(grid.world_to_cell(get_global_mouse_position()))
	elif mouse_event.button_index == MOUSE_BUTTON_WHEEL_UP:
		camera_zoom_requested.emit(1.1)
	elif mouse_event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
		camera_zoom_requested.emit(0.9)


func _ensure_key_action(action: String, physical_keycode: Key) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)

	if not InputMap.action_get_events(action).is_empty():
		return

	var event := InputEventKey.new()
	event.physical_keycode = physical_keycode
	InputMap.action_add_event(action, event)
