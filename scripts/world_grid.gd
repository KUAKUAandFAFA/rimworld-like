class_name WorldGrid
extends Node2D

const TERRAIN_SOIL := 0
const TERRAIN_GRASS := 1
const TERRAIN_STONE := 2
const TERRAIN_WATER := 3

@export var map_width := 36
@export var map_height := 24
@export var cell_size := 32

var _terrain: Array[int] = []
var _astar := AStarGrid2D.new()


func _ready() -> void:
	generate_map()


func generate_map() -> void:
	_terrain.clear()
	_terrain.resize(map_width * map_height)

	for y in range(map_height):
		for x in range(map_width):
			var cell := Vector2i(x, y)
			var roll := _terrain_roll(cell)

			if roll < 0.08:
				_set_terrain(cell, TERRAIN_WATER)
			elif roll > 0.84 and x > 3 and y > 3:
				_set_terrain(cell, TERRAIN_STONE)
			elif roll > 0.48:
				_set_terrain(cell, TERRAIN_GRASS)
			else:
				_set_terrain(cell, TERRAIN_SOIL)

	_prepare_pathfinder()
	queue_redraw()


func world_to_cell(world_position: Vector2) -> Vector2i:
	return Vector2i(floori(world_position.x / cell_size), floori(world_position.y / cell_size))


func cell_to_world(cell: Vector2i) -> Vector2:
	return Vector2(cell.x * cell_size + cell_size * 0.5, cell.y * cell_size + cell_size * 0.5)


func is_cell_in_bounds(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.y >= 0 and cell.x < map_width and cell.y < map_height


func is_cell_walkable(cell: Vector2i) -> bool:
	if not is_cell_in_bounds(cell):
		return false

	var terrain := _get_terrain(cell)
	return terrain != TERRAIN_STONE and terrain != TERRAIN_WATER


func find_path(start_cell: Vector2i, target_cell: Vector2i) -> PackedVector2Array:
	if not is_cell_walkable(start_cell) or not is_cell_walkable(target_cell):
		return PackedVector2Array()

	return _astar.get_point_path(start_cell, target_cell)


func _prepare_pathfinder() -> void:
	_astar.region = Rect2i(Vector2i.ZERO, Vector2i(map_width, map_height))
	_astar.cell_size = Vector2(cell_size, cell_size)
	_astar.offset = Vector2(cell_size * 0.5, cell_size * 0.5)
	_astar.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
	_astar.update()

	for y in range(map_height):
		for x in range(map_width):
			var cell := Vector2i(x, y)
			_astar.set_point_solid(cell, not is_cell_walkable(cell))


func _terrain_roll(cell: Vector2i) -> float:
	var wave := sin(cell.x * 0.37) * 0.26 + cos(cell.y * 0.41) * 0.22
	var basin := sin((cell.x + cell.y) * 0.18) * 0.18
	var seed := fposmod(sin(float(cell.x * 928371 + cell.y * 123123)) * 43758.5453, 1.0)
	return clamp(0.5 + wave + basin + (seed - 0.5) * 0.24, 0.0, 1.0)


func _set_terrain(cell: Vector2i, terrain: int) -> void:
	_terrain[_to_index(cell)] = terrain


func _get_terrain(cell: Vector2i) -> int:
	return _terrain[_to_index(cell)]


func _to_index(cell: Vector2i) -> int:
	return cell.y * map_width + cell.x


func _draw() -> void:
	if _terrain.size() != map_width * map_height:
		return

	for y in range(map_height):
		for x in range(map_width):
			var cell := Vector2i(x, y)
			var rect := Rect2(Vector2(x * cell_size, y * cell_size), Vector2(cell_size, cell_size))

			draw_rect(rect, _terrain_color(_get_terrain(cell)))
			draw_rect(rect, Color(0.1, 0.12, 0.12, 0.35), false, 1.0)


func _terrain_color(terrain: int) -> Color:
	match terrain:
		TERRAIN_GRASS:
			return Color(0.27, 0.46, 0.23)
		TERRAIN_STONE:
			return Color(0.34, 0.35, 0.34)
		TERRAIN_WATER:
			return Color(0.16, 0.34, 0.48)
		_:
			return Color(0.48, 0.40, 0.28)
