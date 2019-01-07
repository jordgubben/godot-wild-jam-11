extends Control
onready var main = get_node("../../Main")

signal init_dialogue


func _physics_process(delta): # just to update the label
	var text = "Variables: \n" + str(PROGRESS.variables) + "\n \n Dialogues: \n" + str(PROGRESS.dialogues)
	get_node("../ColorRect2/Label").text = text
	
	
func press_next():
	main.next()


func init_a():
	emit_signal("init_dialogue", "just_text")


func init_b():
	emit_signal("init_dialogue", "question")


func init_c():
	emit_signal("init_dialogue", "complex")


func clear():
	if PROGRESS.variables.size() > 0:
		for n in PROGRESS.variables:
			PROGRESS.variables.erase(n)
	if PROGRESS.dialogues.size() > 0:
		for n in PROGRESS.dialogues:
			PROGRESS.dialogues.erase(n)


func set_var():
	PROGRESS.variables['var1'] = true
