extends "res://addons/gut/test.gd"

var DialogPlayer = preload("res://dialog/DialogPlayer.tscn")
var SpokenLine = load("res://dialog/SpokenLine.gd")

var instance:DialogPlayer = null
func before_each():
	instance = DialogPlayer.instance()

func test_displaying_first_line():
	# Given the first node is a SpokenLine with some text
	var line = SpokenLine.new()
	line.text = "Some text"
	instance.add_child(line)

	# When adding to tree
	instance._ready()

	# Then only the line from the first spoken line
	# is displayed in the GUI
	assert_eq(
		line.text,
		instance.get_node("speach-panel/text").text)


func test_filter_out_lines():
	# Given the first node is a SpokenLine
	var line = SpokenLine.new()
	instance.add_child(line)

	# And the second line is something unrelated
	instance.add_child(Sprite.new())

	# When filtering out lines
	var lines = instance.filter_out_lines()

	# Then only the SpokenLine is returend
	assert_eq(lines, [line])
