class_name DebugInspector
extends CanvasLayer

const PANEL_WIDTH := 360.0
const PANEL_HEIGHT := 490.0
const PANEL_MARGIN := 12.0

@export var visible_by_default := true

var _summary_label: Label
var _snapshot: Dictionary = {}


func _ready() -> void:
	visible = visible_by_default
	_build_panel()
	_refresh()


func set_snapshot(snapshot: Dictionary) -> void:
	_snapshot = snapshot.duplicate(true)
	_refresh()


func _unhandled_input(event: InputEvent) -> void:
	if event is not InputEventKey:
		return

	var key_event := event as InputEventKey
	if not key_event.pressed or key_event.echo:
		return

	if key_event.keycode == KEY_F3:
		visible = not visible
		get_viewport().set_input_as_handled()


func _build_panel() -> void:
	var panel := PanelContainer.new()
	panel.name = "Panel"
	panel.mouse_filter = Control.MOUSE_FILTER_PASS
	panel.anchor_left = 1.0
	panel.anchor_right = 1.0
	panel.anchor_top = 0.0
	panel.anchor_bottom = 0.0
	panel.offset_left = -PANEL_WIDTH - PANEL_MARGIN
	panel.offset_right = -PANEL_MARGIN
	panel.offset_top = PANEL_MARGIN
	panel.offset_bottom = PANEL_MARGIN + PANEL_HEIGHT
	panel.add_theme_stylebox_override("panel", _panel_style())
	add_child(panel)

	var margin := MarginContainer.new()
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_bottom", 8)
	panel.add_child(margin)

	var scroll_container := ScrollContainer.new()
	scroll_container.name = "ScrollContainer"
	scroll_container.mouse_filter = Control.MOUSE_FILTER_STOP
	scroll_container.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll_container.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	scroll_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	margin.add_child(scroll_container)

	_summary_label = Label.new()
	_summary_label.name = "SummaryLabel"
	_summary_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_summary_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_summary_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_summary_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_summary_label.add_theme_font_size_override("font_size", 12)
	_summary_label.add_theme_color_override("font_color", Color(0.88, 0.93, 0.90))
	scroll_container.add_child(_summary_label)


func _panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.04, 0.05, 0.055, 0.78)
	style.border_color = Color(0.45, 0.58, 0.52, 0.9)
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_right = 4
	style.corner_radius_bottom_left = 4
	return style


func _refresh() -> void:
	if _summary_label == null:
		return

	_summary_label.text = "\n".join(_build_lines())


func _build_lines() -> PackedStringArray:
	var lines := PackedStringArray()
	lines.append("Debug Inspector")
	lines.append("Mode: %s" % String(_snapshot.get("command_mode", "Unknown")))
	lines.append("Status: %s" % String(_snapshot.get("status", "Unknown")))
	lines.append("Last failure: %s" % String(_snapshot.get("last_failure", "None")))
	lines.append("Failure source: %s" % String(_snapshot.get("last_failure_source", "None")))
	_append_work_loop(lines)
	_append_selected_cell(lines)
	_append_designations(lines)
	_append_stockpile_zones(lines)
	_append_item_stacks(lines)
	_append_pawn(lines)
	_append_jobs(lines)
	return lines


func _append_work_loop(lines: PackedStringArray) -> void:
	var work_loop: Dictionary = _snapshot.get("work_loop", {})
	lines.append("Work loop: %s" % String(work_loop.get("state", "Unknown")))
	lines.append("  detail: %s" % String(work_loop.get("detail", "None")))
	lines.append("")


func _append_selected_cell(lines: PackedStringArray) -> void:
	var selected: Dictionary = _snapshot.get("selected_cell", {})
	if not bool(selected.get("has_selection", false)):
		lines.append("Cell: none")
		return

	var cell: Vector2i = selected.get("cell", Vector2i.ZERO)
	lines.append("Cell: %s" % _format_cell(cell))
	lines.append("  in bounds: %s  walkable: %s" % [
		_yes_no(bool(selected.get("in_bounds", false))),
		_yes_no(bool(selected.get("walkable", false))),
	])
	lines.append("  resource: %s" % String(selected.get("resource", "None")))
	lines.append("  stockpile: %s" % String(selected.get("stockpile_zone", "None")))
	lines.append("  item stack: %s" % String(selected.get("item_stack", "None")))
	lines.append("  designation: %s" % String(selected.get("designation", "None")))


func _append_designations(lines: PackedStringArray) -> void:
	var designations: Dictionary = _snapshot.get("designations", {})
	lines.append("")
	lines.append("Designations: %d" % int(designations.get("count", 0)))
	_append_named_lines(lines, "  mark", designations.get("designations", PackedStringArray()))


func _append_stockpile_zones(lines: PackedStringArray) -> void:
	var stockpile_zones: Dictionary = _snapshot.get("stockpile_zones", {})
	lines.append("")
	lines.append("Stockpile zones: %d" % int(stockpile_zones.get("count", 0)))
	_append_named_lines(lines, "  zone", stockpile_zones.get("zones", PackedStringArray()))


func _append_item_stacks(lines: PackedStringArray) -> void:
	var item_stacks: Dictionary = _snapshot.get("item_stacks", {})
	lines.append("")
	lines.append("Item stacks: %d" % int(item_stacks.get("count", 0)))
	_append_named_lines(lines, "  stack", item_stacks.get("stacks", PackedStringArray()))


func _append_pawn(lines: PackedStringArray) -> void:
	var pawn: Dictionary = _snapshot.get("pawn", {})
	var cell: Vector2i = pawn.get("cell", Vector2i.ZERO)
	lines.append("")
	lines.append("Pawn")
	lines.append("  cell: %s  moving: %s" % [
		_format_cell(cell),
		_yes_no(bool(pawn.get("moving", false))),
	])
	lines.append("  path: %d/%d remaining %d" % [
		int(pawn.get("path_index", 0)),
		int(pawn.get("path_points", 0)),
		int(pawn.get("path_remaining", 0)),
	])
	lines.append("  carrying: %s" % String(pawn.get("carrying", "None")))


func _append_jobs(lines: PackedStringArray) -> void:
	var jobs: Dictionary = _snapshot.get("jobs", {})
	lines.append("")
	lines.append("Jobs")
	lines.append("  queued: %d  active: %d" % [
		int(jobs.get("queued_count", 0)),
		int(jobs.get("active_count", 0)),
	])
	_append_named_lines(lines, "  current", jobs.get("active_jobs", PackedStringArray()))
	_append_named_lines(lines, "  pending", jobs.get("queued_jobs", PackedStringArray()))


func _append_named_lines(lines: PackedStringArray, label: String, values: Variant) -> void:
	if values.is_empty():
		lines.append("%s: none" % label)
		return

	for line in values:
		lines.append("%s: %s" % [label, String(line)])


func _format_cell(cell: Vector2i) -> String:
	return "(%d, %d)" % [cell.x, cell.y]


func _yes_no(value: bool) -> String:
	return "yes" if value else "no"
