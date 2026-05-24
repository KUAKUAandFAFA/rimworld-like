class_name ItemStack
extends RefCounted

var id := ""
var item_def: ItemDef
var amount := 0
var cell := Vector2i.ZERO
var reserved_by := ""


func _init(new_id: String = "", new_item_def: ItemDef = null, new_amount: int = 0, new_cell: Vector2i = Vector2i.ZERO) -> void:
	id = new_id
	item_def = new_item_def
	amount = maxi(0, new_amount)
	cell = new_cell


func item_id() -> String:
	if item_def == null:
		return ""

	return item_def.id


func label() -> String:
	if item_def == null:
		return "Invalid"

	return item_def.label()


func is_reserved() -> bool:
	return reserved_by != ""


func reserve(owner_id: String) -> bool:
	if owner_id == "" or is_reserved():
		return false

	reserved_by = owner_id
	return true


func clear_reservation(owner_id: String = "") -> bool:
	if not is_reserved():
		return false

	if owner_id != "" and owner_id != reserved_by:
		return false

	reserved_by = ""
	return true


func can_merge_with(other_item_def: ItemDef, target_cell: Vector2i) -> bool:
	if item_def == null or other_item_def == null:
		return false

	return item_def.id == other_item_def.id and cell == target_cell and not is_reserved()


func add_amount(delta: int) -> void:
	amount = maxi(0, amount + delta)


func debug_summary() -> String:
	var summary := "%s %s x%d at (%d, %d)" % [
		id,
		label(),
		amount,
		cell.x,
		cell.y,
	]

	if is_reserved():
		summary += " reserved by %s" % reserved_by

	return summary


func to_save_dict() -> Dictionary:
	return {
		"id": id,
		"item_id": item_id(),
		"amount": amount,
		"cell": {
			"x": cell.x,
			"y": cell.y,
		},
		"reserved_by": reserved_by,
	}
