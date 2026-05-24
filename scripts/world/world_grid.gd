class_name WorldGrid
extends Node2D

const RESOURCE_FOOD := "food"
const RESOURCE_WOOD := "wood"

@export var map_width := 36
@export var map_height := 24
@export var cell_size := 32
@export var soil_terrain: TerrainDef = preload("res://resources/terrain/soil.tres")
@export var grass_terrain: TerrainDef = preload("res://resources/terrain/grass.tres")
@export var stone_terrain: TerrainDef = preload("res://resources/terrain/stone.tres")
@export var water_terrain: TerrainDef = preload("res://resources/terrain/water.tres")
@export var food_item_def: ItemDef = preload("res://resources/items/food.tres")
@export var wood_item_def: ItemDef = preload("res://resources/items/wood.tres")

var stockpile_cell := Vector2i(5, 5)

var _terrain: Array[TerrainDef] = []
var _resources: Dictionary = {}
var _astar := AStarGrid2D.new()


func _ready() -> void:
	generate_map()


func configure_definitions(definitions: DefinitionRegistry) -> void:
	if definitions == null:
		return

	if not definitions.is_loaded():
		definitions.load_all()

	soil_terrain = _terrain_or_fallback(definitions, "soil", soil_terrain)
	grass_terrain = _terrain_or_fallback(definitions, "grass", grass_terrain)
	stone_terrain = _terrain_or_fallback(definitions, "stone", stone_terrain)
	water_terrain = _terrain_or_fallback(definitions, "water", water_terrain)
	food_item_def = _item_or_fallback(definitions, RESOURCE_FOOD, food_item_def)
	wood_item_def = _item_or_fallback(definitions, RESOURCE_WOOD, wood_item_def)


func generate_map() -> void:
	_terrain.clear()
	_terrain.resize(map_width * map_height)
	_resources.clear()

	for y in range(map_height):
		for x in range(map_width):
			var cell := Vector2i(x, y)
			var roll := _terrain_roll(cell)

			if roll < 0.08:
				_set_terrain(cell, water_terrain)
			elif roll > 0.84 and x > 3 and y > 3:
				_set_terrain(cell, stone_terrain)
			elif roll > 0.48:
				_set_terrain(cell, grass_terrain)
			else:
				_set_terrain(cell, soil_terrain)

	_place_demo_sites()
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
	return terrain != null and terrain.walkable


func find_path(start_cell: Vector2i, target_cell: Vector2i) -> PackedVector2Array:
	if not is_cell_walkable(start_cell) or not is_cell_walkable(target_cell):
		return PackedVector2Array()

	return _astar.get_point_path(start_cell, target_cell)


func has_resource(cell: Vector2i) -> bool:
	return _resources.has(cell)


func get_resource_at(cell: Vector2i) -> Dictionary:
	if not _resources.has(cell):
		return {}

	return _resources[cell].duplicate()


func harvest_resource(cell: Vector2i, amount: int = 1) -> Dictionary:
	if not _resources.has(cell) or amount <= 0:
		return {}

	var resource: Dictionary = _resources[cell]
	var available_amount := int(resource.get("amount", 0))
	if available_amount <= 0:
		_resources.erase(cell)
		queue_redraw()
		return {}

	var harvested_amount := mini(amount, available_amount)
	resource["amount"] = available_amount - harvested_amount
	if int(resource["amount"]) <= 0:
		_resources.erase(cell)
	else:
		_resources[cell] = resource

	queue_redraw()
	return {
		"item_def": resource.get("item_def", null),
		"amount": harvested_amount,
	}


func get_stockpile_cell() -> Vector2i:
	return stockpile_cell


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
	return clampf(0.5 + wave + basin + (seed - 0.5) * 0.24, 0.0, 1.0)


func _place_demo_sites() -> void:
	stockpile_cell = Vector2i(5, 5)
	_set_terrain(stockpile_cell, soil_terrain)

	_place_resource(Vector2i(10, 6), food_item_def, 3)
	_place_resource(Vector2i(13, 9), food_item_def, 3)
	_place_resource(Vector2i(19, 7), wood_item_def, 4)
	_place_resource(Vector2i(23, 13), wood_item_def, 4)
	_place_resource(Vector2i(15, 16), food_item_def, 2)


func _place_resource(cell: Vector2i, item_def: ItemDef, amount: int) -> void:
	if not is_cell_in_bounds(cell) or item_def == null or amount <= 0:
		return

	_set_terrain(cell, grass_terrain)
	_resources[cell] = {
		"item_def": item_def,
		"amount": amount,
	}


func _set_terrain(cell: Vector2i, terrain: TerrainDef) -> void:
	_terrain[_to_index(cell)] = terrain


func _get_terrain(cell: Vector2i) -> TerrainDef:
	return _terrain[_to_index(cell)]


func _to_index(cell: Vector2i) -> int:
	return cell.y * map_width + cell.x


func _terrain_or_fallback(definitions: DefinitionRegistry, id: String, fallback: TerrainDef) -> TerrainDef:
	var terrain_def := definitions.get_terrain(id)
	if terrain_def == null:
		return fallback

	return terrain_def


func _item_or_fallback(definitions: DefinitionRegistry, id: String, fallback: ItemDef) -> ItemDef:
	var item_def := definitions.get_item(id)
	if item_def == null:
		return fallback

	return item_def


func _draw() -> void:
	if _terrain.size() != map_width * map_height:
		return

	for y in range(map_height):
		for x in range(map_width):
			var cell := Vector2i(x, y)
			var rect := Rect2(Vector2(x * cell_size, y * cell_size), Vector2(cell_size, cell_size))

			draw_rect(rect, _terrain_color(_get_terrain(cell)))
			draw_rect(rect, Color(0.1, 0.12, 0.12, 0.35), false, 1.0)

	_draw_stockpile()
	_draw_resources()


func _terrain_color(terrain: TerrainDef) -> Color:
	if terrain == null:
		return Color(0.48, 0.40, 0.28)

	return terrain.color


func _draw_stockpile() -> void:
	var rect := Rect2(Vector2(stockpile_cell.x * cell_size, stockpile_cell.y * cell_size), Vector2(cell_size, cell_size))
	draw_rect(rect.grow(-4.0), Color(0.22, 0.28, 0.34))
	draw_rect(rect.grow(-4.0), Color(0.82, 0.78, 0.58), false, 2.0)

	var center := cell_to_world(stockpile_cell)
	draw_line(center + Vector2(-7, -7), center + Vector2(7, 7), Color(0.82, 0.78, 0.58), 2.0, true)
	draw_line(center + Vector2(7, -7), center + Vector2(-7, 7), Color(0.82, 0.78, 0.58), 2.0, true)


func _draw_resources() -> void:
	for raw_cell in _resources.keys():
		var cell: Vector2i = raw_cell
		var resource: Dictionary = _resources[cell]
		var item_def := resource.get("item_def") as ItemDef
		var amount := int(resource.get("amount", 0))
		var center := cell_to_world(cell)

		if item_def == food_item_def:
			draw_circle(center, 8.0, item_def.color)
			draw_circle(center + Vector2(-6, 2), 4.0, Color(0.95, 0.36, 0.36))
			draw_circle(center + Vector2(6, 3), 4.0, Color(0.95, 0.36, 0.36))
		elif item_def == wood_item_def:
			var log_rect := Rect2(center - Vector2(11, 6), Vector2(22, 12))
			draw_rect(log_rect, item_def.color)
			draw_rect(log_rect, Color(0.18, 0.10, 0.05), false, 2.0)

		if amount > 1:
			draw_circle(center + Vector2(10, -10), 5.0, Color(0.08, 0.09, 0.08))
