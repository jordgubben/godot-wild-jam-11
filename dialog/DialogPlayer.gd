extends Control
class_name DialogPlayer, "./DialogPlayer_icon.png"

onready var text_label:RichTextLabel = get_node("speach-panel/text")

func _ready():
	var first_line = filter_out_lines()[0]
	text_label.text = first_line.text

func filter_out_lines():
	var lines : Array = []
	for c in get_children():
		if( c.has_meta("dialog-line")):
			lines.append(c)

	return lines