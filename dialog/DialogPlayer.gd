extends Control
class_name DialogPlayer, "./DialogPlayer_icon.png"

onready var text_label:RichTextLabel = get_node("speach-panel/text")

signal completed

var _current_line: Node = null

func _ready():
	show_next()

func _on_ok_pressed():
	show_next()

func show_next():
	var next = find_next()

	if (next):
		display(next)
	else:
		emit_signal("completed")

func find_next():
	# Start from the beginning,
	# unless there is already a curren line selected
	var index = 0
	if _current_line != null:
		index = _current_line.get_index() + 1

	# Return the next child node that's a dialog line
	while index < get_child_count():
		var child = get_child(index)
		if is_dialog_line(child):
			return child
		index += 1

	# Notging found :(
	return null

func display(line):
	text_label.text = line.text
	_current_line = line

func is_dialog_line(node):
	return node.has_meta("dialog-line")
