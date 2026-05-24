class_name ItemDef
extends Resource

@export var id: String = ""
@export var display_name: String = ""
@export var color: Color = Color.WHITE


func label() -> String:
	if display_name != "":
		return display_name

	return id.capitalize()
