class_name GameRoot
extends Node2D

const INVALID_CELL := Vector2i(-1, -1)
const HARVEST_JOB_ID := "harvest"

@export var camera_speed := 520.0

@onready var grid: WorldGrid = $WorldGrid
@onready var pawn: Pawn = $Pawn
@onready var definition_registry: DefinitionRegistry = $DefinitionRegistry
@onready var command_mode_model: CommandModeModel = $CommandModeModel
@onready var job_queue: JobQueue = $JobQueue
@onready var stockpile: StockpileSystem = $StockpileSystem
@onready var harvest_job_driver: HarvestJobDriver = $HarvestJobDriver
@onready var input_controller: PlayerInputController = $InputController
@onready var camera: Camera2D = $Camera2D
@onready var hud: ColonyHud = $Hud
@onready var debug_inspector: DebugInspector = $DebugInspector

var _selected_cell := INVALID_CELL
var _status_text := "Idle"
var _last_failure_reason := "None"
var _debug_refresh_elapsed := 0.0


func _ready() -> void:
	camera.make_current()
	if not definition_registry.is_loaded():
		definition_registry.load_all()
	grid.configure_definitions(definition_registry)
	grid.generate_map()
	input_controller.configure(grid)
	harvest_job_driver.configure(grid, pawn, stockpile, job_queue)

	_connect_signals()
	_on_command_mode_changed(command_mode_model.get_mode(), command_mode_model.get_mode_label())
	_register_initial_stockpile_items()
	_spawn_pawn()
	_update_hud()
	_update_debug_inspector()


func _process(delta: float) -> void:
	if debug_inspector == null or not debug_inspector.visible:
		return

	_debug_refresh_elapsed += delta
	if _debug_refresh_elapsed >= 0.2:
		_debug_refresh_elapsed = 0.0
		_update_debug_inspector()


func _connect_signals() -> void:
	if not input_controller.primary_cell_clicked.is_connected(_on_primary_cell_clicked):
		input_controller.primary_cell_clicked.connect(_on_primary_cell_clicked)
	if not input_controller.camera_pan_requested.is_connected(_on_camera_pan_requested):
		input_controller.camera_pan_requested.connect(_on_camera_pan_requested)
	if not input_controller.camera_zoom_requested.is_connected(_on_camera_zoom_requested):
		input_controller.camera_zoom_requested.connect(_on_camera_zoom_requested)
	if not input_controller.command_mode_requested.is_connected(_on_command_mode_requested):
		input_controller.command_mode_requested.connect(_on_command_mode_requested)
	if not hud.command_mode_requested.is_connected(_on_command_mode_requested):
		hud.command_mode_requested.connect(_on_command_mode_requested)
	if not command_mode_model.mode_changed.is_connected(_on_command_mode_changed):
		command_mode_model.mode_changed.connect(_on_command_mode_changed)
	if not pawn.arrived.is_connected(_on_pawn_arrived):
		pawn.arrived.connect(_on_pawn_arrived)
	if not harvest_job_driver.status_changed.is_connected(_set_status):
		harvest_job_driver.status_changed.connect(_set_status)
	if not job_queue.job_completed.is_connected(_on_job_completed):
		job_queue.job_completed.connect(_on_job_completed)
	if not job_queue.job_failed.is_connected(_on_job_failed):
		job_queue.job_failed.connect(_on_job_failed)
	if not stockpile.stockpile_changed.is_connected(_on_stockpile_changed):
		stockpile.stockpile_changed.connect(_on_stockpile_changed)


func _register_initial_stockpile_items() -> void:
	stockpile.register_item(definition_registry.get_item(WorldGrid.RESOURCE_FOOD))
	stockpile.register_item(definition_registry.get_item(WorldGrid.RESOURCE_WOOD))


func _spawn_pawn() -> void:
	pawn.cell_size = grid.cell_size

	var spawn_cell := _find_spawn_cell()
	pawn.place_at(spawn_cell, grid.cell_to_world(spawn_cell))
	camera.position = grid.cell_to_world(spawn_cell)


func _on_primary_cell_clicked(target_cell: Vector2i) -> void:
	_select_cell(target_cell)

	match command_mode_model.get_mode():
		CommandModeModel.MODE_MOVE:
			_handle_move_command(target_cell)
		CommandModeModel.MODE_HARVEST:
			_handle_harvest_command(target_cell)
		CommandModeModel.MODE_CANCEL:
			_handle_cancel_command(target_cell)
		_:
			_set_failure_status("Unknown command mode")


func _handle_move_command(target_cell: Vector2i) -> void:
	if harvest_job_driver.is_busy():
		_set_failure_status("Pawn busy")
		return

	if not grid.is_cell_walkable(target_cell):
		_set_failure_status("Blocked")
		return

	_move_pawn_directly(target_cell)


func _handle_harvest_command(target_cell: Vector2i) -> void:
	if harvest_job_driver.is_busy():
		_set_failure_status("Pawn busy")
		return

	if not grid.has_resource(target_cell):
		_set_failure_status("No resource")
		return

	_queue_harvest_job(target_cell)


func _handle_cancel_command(_target_cell: Vector2i) -> void:
	_set_failure_status("Nothing to cancel")


func _queue_harvest_job(resource_cell: Vector2i) -> void:
	var resource := grid.get_resource_at(resource_cell)
	if resource.is_empty():
		_set_failure_status("No resource")
		return

	var item_def := resource.get("item_def") as ItemDef
	var harvest_job_def := definition_registry.get_job(HARVEST_JOB_ID)
	if harvest_job_def == null:
		_set_failure_status("Missing harvest job definition")
		return

	var job := JobInstance.new(harvest_job_def, resource_cell, item_def, 1)
	job_queue.add_job(job)
	_clear_last_failure()
	_start_next_job_if_idle()


func _start_next_job_if_idle() -> void:
	if harvest_job_driver.is_busy() or pawn.is_moving():
		return

	var job := job_queue.claim_next_job(pawn)
	if job == null:
		return

	if harvest_job_driver.can_run(job):
		harvest_job_driver.start_job(job)
	else:
		job_queue.fail_job(job, "Unsupported job")


func _move_pawn_directly(target_cell: Vector2i) -> void:
	var path := grid.find_path(pawn.current_cell, target_cell)
	if path.is_empty() and pawn.current_cell != target_cell:
		_set_failure_status("No path")
		return

	pawn.set_path(path)
	_clear_last_failure()
	_set_status("Moving")


func _on_pawn_arrived(_cell: Vector2i) -> void:
	if not harvest_job_driver.is_busy() and _status_text == "Moving":
		_set_status("Idle")

	_start_next_job_if_idle()


func _on_job_completed(_job: JobInstance) -> void:
	_start_next_job_if_idle()


func _on_job_failed(_job: JobInstance, reason: String) -> void:
	_set_failure_status(reason)
	_start_next_job_if_idle()


func _on_stockpile_changed(_snapshot: Dictionary) -> void:
	_update_hud()


func _on_camera_pan_requested(direction: Vector2, delta: float) -> void:
	camera.position += direction * camera_speed * delta / camera.zoom.x


func _on_camera_zoom_requested(amount: float) -> void:
	camera.zoom = Vector2.ONE * clampf(camera.zoom.x * amount, 0.55, 2.5)


func _on_command_mode_requested(mode: String) -> void:
	command_mode_model.set_mode(mode)


func _on_command_mode_changed(mode: String, label: String) -> void:
	if hud != null:
		hud.set_command_mode(mode, label)

	_update_debug_inspector()


func _set_status(text: String) -> void:
	_status_text = text
	pawn.status_text = text
	_update_hud()
	_update_debug_inspector()


func _set_failure_status(text: String) -> void:
	_last_failure_reason = text
	_set_status(text)


func _clear_last_failure() -> void:
	_last_failure_reason = "None"


func _update_hud() -> void:
	if hud == null:
		return

	hud.set_status(_status_text)
	hud.set_stockpile_snapshot(stockpile.get_snapshot())


func _update_debug_inspector() -> void:
	if debug_inspector == null:
		return

	debug_inspector.set_snapshot({
		"status": _status_text,
		"last_failure": _last_failure_reason,
		"command_mode": command_mode_model.get_mode_label(),
		"selected_cell": _selected_cell_debug_snapshot(),
		"pawn": pawn.get_debug_snapshot(),
		"jobs": job_queue.get_debug_snapshot(),
	})


func _select_cell(cell: Vector2i) -> void:
	_selected_cell = cell
	queue_redraw()
	_update_debug_inspector()


func _selected_cell_debug_snapshot() -> Dictionary:
	if _selected_cell == INVALID_CELL:
		return {
			"has_selection": false,
		}

	var resource := grid.get_resource_at(_selected_cell)
	return {
		"has_selection": true,
		"cell": _selected_cell,
		"in_bounds": grid.is_cell_in_bounds(_selected_cell),
		"walkable": grid.is_cell_walkable(_selected_cell),
		"resource": _resource_debug_text(resource),
	}


func _resource_debug_text(resource: Dictionary) -> String:
	if resource.is_empty():
		return "None"

	var item_def := resource.get("item_def") as ItemDef
	var amount := int(resource.get("amount", 0))
	if item_def == null:
		return "Invalid x%d" % amount

	return "%s x%d" % [item_def.label(), amount]


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
	if _selected_cell == INVALID_CELL:
		return

	var rect := Rect2(
		Vector2(_selected_cell.x * grid.cell_size, _selected_cell.y * grid.cell_size),
		Vector2(grid.cell_size, grid.cell_size)
	)
	draw_rect(rect, Color(1.0, 0.86, 0.32, 0.2))
	draw_rect(rect, Color(1.0, 0.86, 0.32), false, 2.0)
