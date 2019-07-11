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

	# Then the line from the first spoken line
	# is displayed in the GUI
	assert_eq(
		instance.get_node("speach-panel/text").text,
		line.text)

func test_show_next():
	# Given the first and second node
	# are both SpokenLine(s) with some text
	var line_1 = SpokenLine.new()
	line_1.text = "Some text 1"
	instance.add_child(line_1)

	var line_2 = SpokenLine.new()
	line_2.text = "Some text 2"
	instance.add_child(line_2)

	# When adding to tree
	instance._ready()

	# And then moving to the next
	instance.show_next()

	# Then the line from the second spoken line
	# is displayed in the GUI
	assert_eq(
		instance.get_node("speach-panel/text").text,
		line_2.text)

func test_reaching_end_emmits_signal():
	# Given the first node is a SpokenLine
	instance.add_child(SpokenLine.new())

	# And a listener is connected
	var catcher = Catcher.new()
	instance.connect("completed", catcher, "catch_0")

	# When reaching the end
	instance._ready()
	instance.show_next()

	# Then the listener has recieved a signal
	assert_eq(
		catcher.caught,
		[])


class Catcher:
	var called = false
	var caught = null
	func catch_0():
		called = true
		caught = []