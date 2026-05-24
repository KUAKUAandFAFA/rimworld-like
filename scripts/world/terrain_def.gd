class_name TerrainDef
extends Resource

@export var id: String = ""
@export var display_name: String = ""
@export var color: Color = Color(0.5, 0.5, 0.5)
@export var walkable: bool = true


func label() -> String:
	if display_name != "":
		return display_name

	return id.capitalize()
