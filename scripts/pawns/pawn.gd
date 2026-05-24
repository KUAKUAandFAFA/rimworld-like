class_name Pawn
extends Node2D

signal arrived(cell: Vector2i)

@export var move_speed := 110.0
@export var cell_size := 32

var current_cell := Vector2i.ZERO
var status_text := "Idle"
var carrying_item: ItemDef
var carrying_amount := 0

var _path := PackedVector2Array()
var _path_index := 0


func place_at(cell: Vector2i, world_position: Vector2) -> void:
	current_cell = cell
	global_position = world_position
	_path.clear()
	_path_index = 0


func set_path(path: PackedVector2Array) -> void:
	_path = path
	_path_index = 1 if path.size() > 1 else 0

	if path.size() <= 1:
		call_deferred("_emit_arrived")


func is_moving() -> bool:
	return _path_index < _path.size()


func set_carrying(item_def: ItemDef, amount: int) -> void:
	carrying_item = item_def
	carrying_amount = maxi(0, amount)
	queue_redraw()


func clear_carrying() -> void:
	carrying_item = null
	carrying_amount = 0
	queue_redraw()


func _process(delta: float) -> void:
	if _path_index >= _path.size():
		return

	var target := _path[_path_index]
	global_position = global_position.move_toward(target, move_speed * delta)

	if global_position.distance_to(target) < 1.0:
		global_position = target
		current_cell = Vector2i(floori(target.x / cell_size), floori(target.y / cell_size))
		_path_index += 1

		if _path_index >= _path.size():
			_path.clear()
			_path_index = 0
			arrived.emit(current_cell)


func _draw() -> void:
	draw_circle(Vector2.ZERO, 10.0, Color(0.92, 0.72, 0.38))
	draw_arc(Vector2.ZERO, 10.0, 0.0, TAU, 24, Color(0.12, 0.08, 0.04), 2.0)
	draw_circle(Vector2(3.5, -2.0), 2.0, Color(0.1, 0.08, 0.06))

	if carrying_item != null and carrying_amount > 0:
		draw_rect(Rect2(Vector2(-6, -22), Vector2(12, 8)), carrying_item.color)
		draw_rect(Rect2(Vector2(-6, -22), Vector2(12, 8)), Color(0.08, 0.06, 0.04), false, 1.0)


func _emit_arrived() -> void:
	arrived.emit(current_cell)
