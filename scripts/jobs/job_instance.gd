class_name JobInstance
extends RefCounted

enum Status { QUEUED, CLAIMED, RUNNING, COMPLETED, FAILED }

var job_def: JobDef
var target_cell := Vector2i.ZERO
var target_item: ItemDef
var amount := 1
var status := Status.QUEUED
var assigned_pawn: Pawn
var failure_reason := ""


func _init(new_job_def: JobDef = null, new_target_cell: Vector2i = Vector2i.ZERO, new_target_item: ItemDef = null, new_amount: int = 1) -> void:
	job_def = new_job_def
	target_cell = new_target_cell
	target_item = new_target_item
	amount = maxi(1, new_amount)


func label() -> String:
	if job_def == null:
		return "Job"

	return job_def.label()


func item_label() -> String:
	if target_item == null:
		return "resource"

	return target_item.label().to_lower()
