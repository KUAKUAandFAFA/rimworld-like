class_name PlayerInputController
extends Node2D

signal primary_cell_clicked(cell: Vector2i)
signal camera_pan_requested(direction: Vector2, delta: float)
signal camera_zoom_requested(amount: float)

var grid: WorldGrid


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
