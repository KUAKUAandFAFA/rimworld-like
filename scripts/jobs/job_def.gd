class_name JobDef
extends Resource

@export var id: String = ""
@export var display_name: String = ""


func label() -> String:
	if display_name != "":
		return display_name

	return id.capitalize()
