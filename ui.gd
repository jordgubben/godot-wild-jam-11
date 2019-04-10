extends Control
onready var dialogue = get_node('../Dialogue')

func _ready():
	# Connect all the signals for the buttons
	$CenterContainer/HBoxContainer/VBoxContainer/Continue.connect('pressed', self, 'press_next')
	$CenterContainer/HBoxContainer/VBoxContainer/InitiateA.connect('pressed', self, 'init_a')
	$CenterContainer/HBoxContainer/VBoxContainer/InitiateB.connect('pressed', self, 'init_b')
	$CenterContainer/HBoxContainer/VBoxContainer/InitiateC.connect('pressed', self, 'init_c')
	$CenterContainer/HBoxContainer/Variables/VBoxContainer/Clear.connect('pressed', self, 'clear')
	$CenterContainer/HBoxContainer/Variables/VBoxContainer/SetVars.connect('pressed', self, 'set_vars')
	pass

func _physics_process(delta): # Just to update the Variables label
	var text = 'Variables: \n' + str(PROGRESS.variables) + '\n \n Dialogues: \n' + str(PROGRESS.dialogues)
	$CenterContainer/HBoxContainer/Variables/Label.text = text


func press_next():
	dialogue.next()


func init_a():
	dialogue.initiate('avatars')


func init_b():
	dialogue.initiate('question')


func init_c():
	dialogue.initiate('complex')


func clear():
	PROGRESS.variables = {}
	PROGRESS.dialogues = {}


func set_vars():
	var varfield1 = $CenterContainer/HBoxContainer/Variables/Var1
	var varfield2 = $CenterContainer/HBoxContainer/Variables/Var2
	var varfield3 = $CenterContainer/HBoxContainer/Variables/Var3
	var varfield4 = $CenterContainer/HBoxContainer/Variables/Var4
	var varfield5 = $CenterContainer/HBoxContainer/Variables/Var5
	
	if varfield1.text:
		PROGRESS.variables['var1'] = varfield1.text
	if varfield2.text:
		PROGRESS.variables['var2'] = int(varfield2.text)
	if varfield3.text:
		PROGRESS.variables['var3'] = int(varfield3.text)
	if varfield4.text:
		PROGRESS.variables['var4'] = int(varfield4.text)
	if varfield5.text:
		PROGRESS.variables['var5'] = int(varfield5.text)
