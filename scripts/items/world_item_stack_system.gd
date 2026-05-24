class_name WorldItemStackSystem
extends Node2D

signal stacks_changed(snapshot: Dictionary)

const STACK_ID_PREFIX := "stack_"

@export var cell_size := 32

var _stacks: Dictionary = {}
var _cell_index: Dictionary = {}
var _item_defs: Dictionary = {}
var _next_numeric_id := 1


func configure(new_cell_size: int) -> void:
	cell_size = maxi(1, new_cell_size)
	queue_redraw()


func register_item(item_def: ItemDef) -> void:
	if item_def == null or item_def.id == "":
		return

	_item_defs[item_def.id] = item_def
	_emit_changed()


func add_or_merge_stack(item_def: ItemDef, amount: int, cell: Vector2i) -> ItemStack:
	if item_def == null or item_def.id == "" or amount <= 0:
		return null

	_item_defs[item_def.id] = item_def

	var stack := _find_merge_target(item_def, cell)
	if stack == null:
		stack = ItemStack.new(_next_stack_id(), item_def, amount, cell)
		_stacks[stack.id] = stack
		_add_stack_to_cell_index(stack)
	else:
		stack.add_amount(amount)

	_emit_changed()
	return stack


func get_stack(stack_id: String) -> ItemStack:
	return _stacks.get(stack_id, null) as ItemStack


func get_stacks_at(cell: Vector2i) -> Array[ItemStack]:
	var stacks: Array[ItemStack] = []
	var stack_ids: Array = _cell_index.get(cell, [])
	for raw_stack_id in stack_ids:
		var stack := get_stack(String(raw_stack_id))
		if stack != null:
			stacks.append(stack)

	return stacks


func reserve_stack(stack_id: String, owner_id: String) -> bool:
	var stack := get_stack(stack_id)
	if stack == null:
		return false

	var reserved := stack.reserve(owner_id)
	if reserved:
		_emit_changed()

	return reserved


func clear_stack_reservation(stack_id: String, owner_id: String = "") -> bool:
	var stack := get_stack(stack_id)
	if stack == null:
		return false

	var cleared := stack.clear_reservation(owner_id)
	if cleared:
		_emit_changed()

	return cleared


func get_inventory_snapshot() -> Dictionary:
	var snapshot := {}
	for raw_item_id in _item_defs.keys():
		var item_id := String(raw_item_id)
		var item_def := _item_defs[item_id] as ItemDef
		snapshot[item_id] = {
			"label": _item_label(item_def, item_id),
			"amount": 0,
		}

	for stack in _sorted_stacks():
		if stack.item_def == null or stack.amount <= 0:
			continue

		var item_id := stack.item_id()
		if not snapshot.has(item_id):
			snapshot[item_id] = {
				"label": stack.label(),
				"amount": 0,
			}

		var entry: Dictionary = snapshot[item_id]
		entry["amount"] = int(entry.get("amount", 0)) + stack.amount
		snapshot[item_id] = entry

	return snapshot


func get_debug_snapshot() -> Dictionary:
	return {
		"count": _stacks.size(),
		"stacks": _stack_debug_lines(),
		"save_data": to_save_data(),
	}


func get_cell_debug_text(cell: Vector2i) -> String:
	var lines := PackedStringArray()
	for stack in get_stacks_at(cell):
		lines.append("%s x%d [%s]" % [stack.label(), stack.amount, stack.id])

	if lines.is_empty():
		return "None"

	return ", ".join(lines)


func to_save_data() -> Array[Dictionary]:
	var save_data: Array[Dictionary] = []
	for stack in _sorted_stacks():
		save_data.append(stack.to_save_dict())

	return save_data


func _find_merge_target(item_def: ItemDef, cell: Vector2i) -> ItemStack:
	for stack in get_stacks_at(cell):
		if stack.can_merge_with(item_def, cell):
			return stack

	return null


func _add_stack_to_cell_index(stack: ItemStack) -> void:
	var stack_ids: Array = _cell_index.get(stack.cell, [])
	if not stack_ids.has(stack.id):
		stack_ids.append(stack.id)

	_cell_index[stack.cell] = stack_ids


func _next_stack_id() -> String:
	var stack_id := "%s%d" % [STACK_ID_PREFIX, _next_numeric_id]
	_next_numeric_id += 1
	while _stacks.has(stack_id):
		stack_id = "%s%d" % [STACK_ID_PREFIX, _next_numeric_id]
		_next_numeric_id += 1

	return stack_id


func _stack_debug_lines() -> PackedStringArray:
	var lines := PackedStringArray()
	for stack in _sorted_stacks():
		lines.append(stack.debug_summary())

	return lines


func _sorted_stacks() -> Array[ItemStack]:
	var stacks: Array[ItemStack] = []
	for stack_id in _sorted_stack_ids():
		var stack := get_stack(stack_id)
		if stack != null:
			stacks.append(stack)

	return stacks


func _sorted_stack_ids() -> PackedStringArray:
	var stack_ids := PackedStringArray()
	for raw_stack_id in _stacks.keys():
		stack_ids.append(String(raw_stack_id))

	stack_ids.sort()
	return stack_ids


func _item_label(item_def: ItemDef, fallback_id: String) -> String:
	if item_def == null:
		return fallback_id.capitalize()

	return item_def.label()


func _emit_changed() -> void:
	stacks_changed.emit(get_debug_snapshot())
	queue_redraw()


func _draw() -> void:
	for stack in _sorted_stacks():
		if stack.item_def == null or stack.amount <= 0:
			continue

		var center := _cell_center(stack.cell)
		var rect := Rect2(center - Vector2(8, 8), Vector2(16, 16))
		draw_rect(rect, stack.item_def.color)
		draw_rect(rect, Color(0.08, 0.07, 0.05), false, 2.0)

		if stack.is_reserved():
			draw_arc(center, 11.0, 0.0, TAU, 24, Color(0.38, 0.74, 1.0), 2.0, true)

		if stack.amount > 1:
			draw_circle(center + Vector2(8, -8), 5.0, Color(0.08, 0.09, 0.08))
			draw_circle(center + Vector2(8, -8), 3.0, Color(0.92, 0.93, 0.86))


func _cell_center(cell: Vector2i) -> Vector2:
	return Vector2(cell.x * cell_size + cell_size * 0.5, cell.y * cell_size + cell_size * 0.5)
