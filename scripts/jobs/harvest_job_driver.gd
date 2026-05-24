class_name HarvestJobDriver
extends JobDriver

const HARVEST_JOB_ID := "harvest"
const PHASE_TO_RESOURCE := "to_resource"
const PHASE_TO_STOCKPILE := "to_stockpile"

var _phase := ""


func configure(new_grid: WorldGrid, new_pawn: Pawn, new_stockpile: StockpileSystem, new_job_queue: JobQueue) -> void:
	super.configure(new_grid, new_pawn, new_stockpile, new_job_queue)

	if pawn != null and not pawn.arrived.is_connected(_on_pawn_arrived):
		pawn.arrived.connect(_on_pawn_arrived)


func can_run(job: JobInstance) -> bool:
	return job != null and job.job_def != null and job.job_def.id == HARVEST_JOB_ID


func start_job(job: JobInstance) -> void:
	if not can_run(job):
		active_job = job
		_fail_active_job("Unsupported job")
		return

	active_job = job
	active_job.status = JobInstance.Status.RUNNING
	_phase = PHASE_TO_RESOURCE

	var resource := grid.get_resource_at(active_job.target_cell)
	if resource.is_empty():
		_fail_active_job("Resource gone")
		return

	var item_def := resource.get("item_def") as ItemDef
	if item_def == null:
		_fail_active_job("Invalid resource")
		return

	active_job.target_item = item_def
	_move_to_cell(active_job.target_cell, "Gathering %s" % active_job.item_label())


func _on_pawn_arrived(cell: Vector2i) -> void:
	if active_job == null:
		return

	if _phase == PHASE_TO_RESOURCE:
		_collect_resource(cell)
	elif _phase == PHASE_TO_STOCKPILE:
		_deliver_resource()


func _collect_resource(_cell: Vector2i) -> void:
	var harvested := grid.harvest_resource(active_job.target_cell, active_job.amount)
	if harvested.is_empty():
		_fail_active_job("Resource gone")
		return

	var item_def := harvested.get("item_def") as ItemDef
	var harvested_amount := int(harvested.get("amount", 0))
	if item_def == null or harvested_amount <= 0:
		_fail_active_job("Invalid harvest")
		return

	pawn.set_carrying(item_def, harvested_amount)
	_phase = PHASE_TO_STOCKPILE
	_move_to_cell(grid.get_stockpile_cell(), "Delivering %s" % item_def.label().to_lower())


func _deliver_resource() -> void:
	if pawn.carrying_item != null and pawn.carrying_amount > 0:
		stockpile.add_item(pawn.carrying_item, pawn.carrying_amount)

	pawn.clear_carrying()

	var finished_job := active_job
	active_job = null
	_phase = ""

	if job_queue != null:
		job_queue.complete_job(finished_job)

	job_finished.emit(finished_job)
	_set_status("Delivered")


func _move_to_cell(cell: Vector2i, status_text: String) -> void:
	var path := grid.find_path(pawn.current_cell, cell)
	if path.is_empty() and pawn.current_cell != cell:
		_fail_active_job("No path")
		return

	pawn.set_path(path)
	_set_status(status_text)


func _fail_active_job(reason: String) -> void:
	if pawn != null:
		pawn.clear_carrying()

	_phase = ""
	super._fail_active_job(reason)
