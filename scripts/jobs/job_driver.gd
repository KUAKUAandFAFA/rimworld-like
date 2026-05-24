class_name JobDriver
extends Node

signal status_changed(text: String)
signal job_finished(job: JobInstance)
signal job_failed(job: JobInstance, reason: String)

var grid: WorldGrid
var pawn: Pawn
var stockpile: StockpileSystem
var item_stacks: WorldItemStackSystem
var job_queue: JobQueue
var active_job: JobInstance


func configure(new_grid: WorldGrid, new_pawn: Pawn, new_stockpile: StockpileSystem, new_job_queue: JobQueue, new_item_stacks: WorldItemStackSystem = null) -> void:
	grid = new_grid
	pawn = new_pawn
	stockpile = new_stockpile
	job_queue = new_job_queue
	item_stacks = new_item_stacks


func is_busy() -> bool:
	return active_job != null


func can_run(_job: JobInstance) -> bool:
	return false


func start_job(_job: JobInstance) -> void:
	pass


func cancel_job(reason: String) -> void:
	if active_job == null:
		return

	_fail_active_job(reason)


func _set_status(text: String) -> void:
	status_changed.emit(text)


func _fail_active_job(reason: String) -> void:
	var failed_job := active_job
	active_job = null

	if job_queue != null:
		job_queue.fail_job(failed_job, reason)

	job_failed.emit(failed_job, reason)
	_set_status(reason)
