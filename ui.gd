extends Control
onready var dialogue = get_node("../Dialogue")

func _ready():
	# Connect all the signals for the buttons
	$Continue.connect("pressed", self, "press_next")
	$InitiateA.connect("pressed", self, "init_a")
	$InitiateB.connect("pressed", self, "init_b")
	$InitiateC.connect("pressed", self, "init_c")
	$Clear.connect("pressed", self, "clear")
	$SetVars.connect("pressed", self, "set_vars")

func _physics_process(delta): # Just to update the Variables label
	var text = "Variables: \n" + str(PROGRESS.variables) + "\n \n Dialogues: \n" + str(PROGRESS.dialogues)
	get_node("../Variables/Label").text = text


func press_next():
	dialogue.next()


func init_a():
	dialogue.initiate("just_text")


func init_b():
	dialogue.initiate("question")


func init_c():
	dialogue.initiate("complex")


func clear():
	PROGRESS.variables = {}
	PROGRESS.dialogues = {}


func set_vars():
	if $Var1.text:
		PROGRESS.variables['var1'] = $Var1.text
	if $Var2.text:
		PROGRESS.variables['var2'] = int($Var2.text)
	if $Var3.text:
		PROGRESS.variables['var3'] = int($Var3.text)
	if $Var4.text:
		PROGRESS.variables['var4'] = int($Var4.text)
	if $Var5.text:
		PROGRESS.variables['var5'] = int($Var5.text)
