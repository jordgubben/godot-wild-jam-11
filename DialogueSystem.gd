extends Control


##### SETUP #####
## Paths ##
var dialogues_folder = "res://dialogues" # Folder where the JSON files will be stored
var choice_scene = load('res://question_choice.tscn') # Base scene for que choices
## Required nodes ##
onready var emitter = get_node("buttons") # The signal emitter node.
onready var frame = $ColorRect # The container node for the dialogues.
onready var label = $ColorRect/RichTextLabel # The label where the text will be displayed.
onready var choices = $ColorRect/Choices # The container node for the choices.
onready var choices_position = $ColorRect/Choices/Position2D # The node used to get the starting Y position for the choices.
onready var timer = $Timer # Timer node.
## Typewriter effect ##
var wait_time = 0.025 # Time interval (in seconds) for the typewriter effect. Set to 0 to disable it. 
var pause_time = 2.0 # Duration of each pause when the typewriter effect is active.
var pause_char = "|" # The character used in the JSON file to define where pauses should be. If you change this you'll need to edit all your dialogue files.
# Other customization options ##
onready var progress = PROGRESS # The AutoLoad script where the interaction log, quest variables, inventory and other useful data should be acessible.
var choice_plus_y = 20 # How much space (in pixels) should be between the choices.
var active_choice = Color(1.0, 1.0, 1.0, 1.0)
var inactive_choice = Color(1.0, 1.0, 1.0, 0.4)
var previous_command = 'ui_up' # Input commmand for the navigating through question choices 
var next_command = 'ui_down' # Input commmand for the navigating through question choices
# END OF SETUP #


# Default values. Don't change them unless you really know what you're doing.
var id
var next_step = 'first'
var dialogue
var phrase
var current = ''
var number_characters = 0

var is_question = false
var current_choice = 0
var number_choices = 0

var pause_index = 0
var paused = false
var pause_array = []






func _ready():
	emitter.connect("init_dialogue", self, "initiate")
	frame.hide() # Hide the dialogue frame



func initiate(file_id): # Load the whole dialogue into a variable
	id = file_id
	var file = File.new()
	file.open('%s/%s.json' % [dialogues_folder, id], file.READ)
	var json = file.get_as_text()
	dialogue = JSON.parse(json).result
	file.close()
	first() # Call the first dialogue block



func clean(): # Resets some variables to prevent errors.
	paused = false
	pause_index = 0
	pause_array = []
	current_choice = 0
	timer.wait_time = wait_time # Resets the typewriter effect delay



func not_question():
	is_question = false



func first():
	frame.show()
	if dialogue.has('repeat'):
		if progress.dialogues.has(id): # Checks if it's the first interaction.
			update_dialogue(dialogue['repeat']) # It's not. Use the 'repeat' block.
		else:
			update_dialogue(dialogue['first']) # It is. Use the 'first' block.
			progress.dialogues[id] = true # Updates the singleton containing the interactions log.
	else:
			update_dialogue(dialogue['first'])



func update_dialogue(step): # step == whole dialogue block
	clean()
	current = step
	
	# Check what kind of interaction the block is 
	match step['type']:
		'text': # Simple text.
			not_question()
			check_pauses(step['content'])
	
			label.bbcode_text = phrase
			next_step = step['next'] if step.has('next') else ''
		'divert': # Simple way to create complex dialogue trees
			not_question()
			match step['condition']:
				'variable':
					if progress.variables.has(step['variable']):
						next_step = step['true'] if progress.variables[step['variable']] else step['false']
					else:
						next_step = step['false']
			next()
		'question': # Moved to question() function to make the code more readable.
			question(step['text'], step['options'], step['next'])
		'action':
			not_question()
			
			next_step = step['next'] if step.has('next') else ''
			match step['value'][0]:
				'variable':
					update_variable(step['value'][1], step['value'][2])
			if step.has('text'):
				check_pauses(step['text'])
				label.bbcode_text = phrase
			else:
				next()
	
	
	if step['type'] != 'divert': # This is outside the "match" to avoid repeating it on every kind of interaction I'll add.
		next_step = current['next'][0] if current.has('next') else ''
	
	number_characters = phrase.length()
	
	if wait_time > 0: # Check if the typewriter effect is active and then starts the timer.
		label.visible_characters = 0
		timer.start()



func check_pauses(string):
	var next_search = 0
	phrase = string
	next_search = (phrase.find('%s' % pause_char, next_search))
	
	if next_search >= 0:
		while next_search != -1:
			pause_array.append(next_search)
			phrase.erase(next_search,1)
			next_search = (phrase.find('%s' % pause_char, next_search))



func next():
	if not dialogue: # Check if is in the middle of a dialogue 
		return
	clean() # Be sure all the variables used before are restored to their default values.
	if wait_time > 0: # Check if the typewriter effect is active.
		if label.visible_characters < number_characters: # Checks if the phrase is complete.
			label.visible_characters = number_characters # Finishes the phrase.
			return # Stop the function here.
	else: # The typewriter effect is disabled so we need to make sure the text is fully displayed.
		label.visible_characters = number_characters
	
	if next_step == '': # Doesn't have a 'next' block.
		dialogue = null
		frame.hide() 
	else:
		label.bbcode_text = ""
		if choices.get_child_count() > 0: # If has choices, remove them.
			for n in choices.get_children():
				choices.remove_child(n)
		else:
			pass
		update_dialogue(dialogue[next_step])



func question(text, options, next):
	check_pauses(text)
	label.bbcode_text = phrase + ' \n'
	var n = 0 # Just a looping var.

	for a in options:
		var choice = choice_scene.instance()
		choice.bbcode_text = a 
		choices.add_child(choice)
		choices.get_child(n).rect_position.y = choices_position.position.y + (choice_plus_y * n)
		if n > 0:
			choices.get_child(n).self_modulate = inactive_choice
		n += 1

	is_question = true
	number_choices = choices.get_child_count() - 1


func change_choice(dir):
	if label.visible_characters >= number_characters: # Make sure the whole question is displayed before the player can answer.
		match dir: # If you want to stop the "loop" effect on the choices, invert the commented sections.
	
			# LOOPING
			'previous': # Looping
				choices.get_child(current_choice).self_modulate = inactive_choice
				current_choice = current_choice - 1 if current_choice > 0 else number_choices
				choices.get_child(current_choice).self_modulate = active_choice
			'next':
				choices.get_child(current_choice).self_modulate = inactive_choice
				current_choice = current_choice + 1 if current_choice < number_choices else 0
				choices.get_child(current_choice).self_modulate = active_choice
	
#			# NOT LOOPING
#			'previous': # Not looping
#				if current_choice == 0:
#					pass
#				else:
#					choices.get_child(current_choice).self_modulate = inactive_choice
#					current_choice = current_choice - 1
#					choices.get_child(current_choice).self_modulate = active_choice
#			'next':
#				if current_choice == number_choices:
#					pass
#				else:
#					choices.get_child(current_choice).self_modulate = inactive_choice
#					current_choice = current_choice + 1
#					choices.get_child(current_choice).self_modulate = active_choice
	
		next_step = current['next'][current_choice]


func update_variable(variable, new_value):
	match typeof(variable):
		TYPE_ARRAY: # Is an array. Loop through the values and assign them.
			var x = 0
			for n in variable:
				PROGRESS.variables[n] = new_value[x]
				x += 1
		TYPE_STRING:
			PROGRESS.variables[variable] = new_value


func _input(event): # This function can be easily replaced. Just make sure you call the function using the right parameters.
	if event.is_action_pressed('%s' % previous_command):
		change_choice('previous')
	if event.is_action_pressed('%s' % next_command):
		change_choice('next')


func _on_Timer_timeout():
	if label.visible_characters < number_characters: # Check if the timer needs to be started
		if paused:
			update_pause()
			return # If in pause, ignore the rest of the function.

		if pause_array.size() > 0: # Check if the phrase have any pauses left.
			if label.visible_characters == pause_array[pause_index]: # pause_char == index of the last character before pause.
				timer.wait_time = pause_time * wait_time * 10
				paused = true
			else:
				label.visible_characters += 1
		else: # Phrase doesn't have any pauses.
			label.visible_characters += 1
		
		timer.start()
	else:
		return

func update_pause():
	if pause_array.size() > (pause_index+1): # Check if the current pause is not the last one. 
		pause_index += 1
	else: # Doesn't have any pauses left.
		pause_array = []
		pause_index = 0
		
	paused = false
	timer.wait_time = wait_time
	timer.start()
