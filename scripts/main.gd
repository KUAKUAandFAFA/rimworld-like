extends Node2D

@onready var grid: WorldGrid = $WorldGrid
@onready var pawn: Pawn = $Pawn
@onready var camera: Camera2D = $Camera2D

var _selected_cell := Vector2i(-1, -1)
var _camera_speed := 520.0


func _ready() -> void:
	camera.make_current()
	pawn.cell_size = grid.cell_size
	var spawn_cell := _find_spawn_cell()
	pawn.place_at(spawn_cell, grid.cell_to_world(spawn_cell))


func _process(delta: float) -> void:
	var movement := Vector2.ZERO

	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
		movement.x -= 1.0
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
		movement.x += 1.0
	if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
		movement.y -= 1.0
	if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
		movement.y += 1.0

	if movement != Vector2.ZERO:
		camera.position += movement.normalized() * _camera_speed * delta / camera.zoom.x


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			_move_pawn_to_mouse()
		elif event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_zoom_camera(1.1)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_zoom_camera(0.9)


func _move_pawn_to_mouse() -> void:
	var target_cell := grid.world_to_cell(get_global_mouse_position())

	if not grid.is_cell_walkable(target_cell):
		return

	_selected_cell = target_cell
	pawn.set_path(grid.find_path(pawn.current_cell, target_cell))
	queue_redraw()


func _zoom_camera(amount: float) -> void:
	var next_zoom := clamp(camera.zoom.x * amount, 0.55, 2.5)
	camera.zoom = Vector2(next_zoom, next_zoom)


func _find_spawn_cell() -> Vector2i:
	var center := Vector2i(floori(grid.map_width / 2.0), floori(grid.map_height / 2.0))

	if grid.is_cell_walkable(center):
		return center

	for radius in range(1, 13):
		for y in range(center.y - radius, center.y + radius + 1):
			for x in range(center.x - radius, center.x + radius + 1):
				var cell := Vector2i(x, y)
				if grid.is_cell_walkable(cell):
					return cell

	return Vector2i.ZERO


func _draw() -> void:
	if _selected_cell.x < 0:
		return

	var rect := Rect2(
		Vector2(_selected_cell.x * grid.cell_size, _selected_cell.y * grid.cell_size),
		Vector2(grid.cell_size, grid.cell_size)
	)
	draw_rect(rect, Color(1.0, 0.86, 0.32, 0.2))
	draw_rect(rect, Color(1.0, 0.86, 0.32), false, 2.0)
