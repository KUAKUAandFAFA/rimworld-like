class_name DefinitionRegistry
extends Node

signal definitions_loaded

const CATEGORY_ITEM := "items"
const CATEGORY_TERRAIN := "terrain"
const CATEGORY_JOB := "jobs"
const REQUIRED_IDS := {
	CATEGORY_ITEM: ["food", "wood"],
	CATEGORY_TERRAIN: ["grass", "soil", "stone", "water"],
	CATEGORY_JOB: ["harvest"],
}

@export var item_folder := "res://resources/items"
@export var terrain_folder := "res://resources/terrain"
@export var job_folder := "res://resources/jobs"

var _items: Dictionary = {}
var _terrain: Dictionary = {}
var _jobs: Dictionary = {}
var _loaded := false


func _ready() -> void:
	load_all()


func load_all() -> void:
	_loaded = false
	_items = _load_folder(item_folder, CATEGORY_ITEM)
	_terrain = _load_folder(terrain_folder, CATEGORY_TERRAIN)
	_jobs = _load_folder(job_folder, CATEGORY_JOB)
	_loaded = true
	_report_missing_required_definitions()
	definitions_loaded.emit()


func is_loaded() -> bool:
	return _loaded


func get_item(id: String) -> ItemDef:
	return _items.get(id, null) as ItemDef


func get_terrain(id: String) -> TerrainDef:
	return _terrain.get(id, null) as TerrainDef


func get_job(id: String) -> JobDef:
	return _jobs.get(id, null) as JobDef


func get_definition(category: String, id: String) -> Resource:
	match category:
		CATEGORY_ITEM:
			return get_item(id)
		CATEGORY_TERRAIN:
			return get_terrain(id)
		CATEGORY_JOB:
			return get_job(id)
		_:
			return null


func has_definition(category: String, id: String) -> bool:
	return get_definition(category, id) != null


func get_definition_ids(category: String) -> PackedStringArray:
	var source: Dictionary = _category_dictionary(category)
	var ids := PackedStringArray()
	for raw_id in source.keys():
		ids.append(String(raw_id))

	ids.sort()
	return ids


func get_definition_count(category: String) -> int:
	return _category_dictionary(category).size()


func get_summary() -> Dictionary:
	return {
		CATEGORY_ITEM: get_definition_ids(CATEGORY_ITEM),
		CATEGORY_TERRAIN: get_definition_ids(CATEGORY_TERRAIN),
		CATEGORY_JOB: get_definition_ids(CATEGORY_JOB),
	}


func get_missing_required_definitions() -> Dictionary:
	var missing := {}
	for raw_category in REQUIRED_IDS.keys():
		var category := String(raw_category)
		var missing_ids := PackedStringArray()
		for raw_id in REQUIRED_IDS[category]:
			var id := String(raw_id)
			if not has_definition(category, id):
				missing_ids.append(id)

		if not missing_ids.is_empty():
			missing[category] = missing_ids

	return missing


func _category_dictionary(category: String) -> Dictionary:
	match category:
		CATEGORY_ITEM:
			return _items
		CATEGORY_TERRAIN:
			return _terrain
		CATEGORY_JOB:
			return _jobs
		_:
			return {}


func _load_folder(folder_path: String, category: String) -> Dictionary:
	var definitions: Dictionary = {}
	var dir := DirAccess.open(folder_path)
	if dir == null:
		push_warning("DefinitionRegistry: missing folder %s" % folder_path)
		return definitions

	dir.list_dir_begin()
	var file_name: String = dir.get_next()
	while file_name != "":
		if not dir.current_is_dir() and file_name.ends_with(".tres"):
			var path := "%s/%s" % [folder_path, file_name]
			var resource: Resource = load(path) as Resource
			if not _matches_category(resource, category):
				push_warning("DefinitionRegistry: skipped unexpected resource at %s" % path)
			else:
				_register_definition(definitions, folder_path, path, resource)

		file_name = dir.get_next()

	dir.list_dir_end()
	return definitions


func _matches_category(resource: Resource, category: String) -> bool:
	match category:
		CATEGORY_ITEM:
			return resource is ItemDef
		CATEGORY_TERRAIN:
			return resource is TerrainDef
		CATEGORY_JOB:
			return resource is JobDef
		_:
			return false


func _register_definition(definitions: Dictionary, folder_path: String, path: String, resource: Resource) -> void:
	var id := String(resource.get("id"))
	if id == "":
		push_warning("DefinitionRegistry: definition at %s has no id" % path)
	elif definitions.has(id):
		push_warning("DefinitionRegistry: duplicate id %s in %s" % [id, folder_path])
	else:
		definitions[id] = resource


func _report_missing_required_definitions() -> void:
	var missing := get_missing_required_definitions()
	for raw_category in missing.keys():
		var category := String(raw_category)
		var missing_ids: PackedStringArray = missing[category]
		push_warning("DefinitionRegistry: missing required %s definitions: %s" % [
			category,
			", ".join(missing_ids),
		])
