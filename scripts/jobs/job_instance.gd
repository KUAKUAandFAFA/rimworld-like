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
var source_designation: Designation


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


static func status_name(status_value: int) -> String:
	match status_value:
		Status.QUEUED:
			return "Queued"
		Status.CLAIMED:
			return "Claimed"
		Status.RUNNING:
			return "Running"
		Status.COMPLETED:
			return "Completed"
		Status.FAILED:
			return "Failed"
		_:
			return "Unknown"


func debug_summary() -> String:
	var summary := "%s %s at (%d, %d)" % [
		label(),
		status_name(status),
		target_cell.x,
		target_cell.y,
	]

	if target_item != null:
		summary += " for %s" % target_item.label().to_lower()

	if failure_reason != "":
		summary += " failed: %s" % failure_reason

	if source_designation != null:
		summary += " from %s" % source_designation.display_label()

	return summary
