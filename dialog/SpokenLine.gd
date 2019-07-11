extends Node
#class_name SpokenLine, "./SpokenLine_icon.png"

export(Texture) var portrait: Texture = null
export(String, MULTILINE) var text: String = ""

func _init():
	set_meta("dialog-line", true)

