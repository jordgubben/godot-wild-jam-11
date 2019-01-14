"""
Godot Open Dialogue - Non-linear conversation system
Author: J. Sena
Version: 1.1
License: CC-BY
URL: https://jsena42.bitbucket.io/god/
Repository: https://bitbucket.org/jsena42/godot-open-dialogue/
"""

extends Control

##### SETUP #####
## Paths ##
var dialogues_folder = 'res://dialogues' # Folder where the JSON files will be stored
var choice_scene = load('res://Choice.tscn') # Base scene for que choices
## Required nodes ##
onready var frame : Node = $Frame # The container node for the dialogues.
onready var label : Node = $Frame/RichTextLabel # The label where the text will be displayed.
onready var choices : Node = $Frame/Choices # The container node for the choices.
onready var timer : Node = $Timer # Timer node.
onready var continue_indicator : Node = $ContinueIndicator # Blinking square displayed when the text is all printed.
onready var animations : Node = $AnimationPlayer
## Typewriter effect ##
var wait_time : float = 0.02 # Time interval (in seconds) for the typewriter effect. Set to 0 to disable it. 
var pause_time : float = 2.0 # Duration of each pause when the typewriter effect is active.
var pause_char : String = '|' # The character used in the JSON file to define where pauses should be. If you change this you'll need to edit all your dialogue files.
var newline_char : String = '@' # The character used in the JSON file to break lines. If you change this you'll need to edit all your dialogue files.
## Other customization options ##
onready var progress = PROGRESS # The AutoLoad script where the interaction log, quest variables, inventory and other useful data should be acessible.
var dialogues_dict = 'dialogues' # The dictionary on "progress" used to keep track of interactions.
var choice_plus_y : int = 2 # How much space (in pixels) should be added between the choices (affected by "choice_height").
var active_choice : Color = Color(1.0, 1.0, 1.0, 1.0)
var inactive_choice : Color = Color(1.0, 1.0, 1.0, 0.4)
var choice_height : int = 20 # Choice label's height
var choice_width : int = 250 # Choice label's width
var choice_margin_vertical : int = 10 # Vertical space (in pixels) between the bottom border of the dialogue frame and the last question (affectd by the "label_margin")
var choice_margin_horizontal : int = 10 # Horizontal space (in pixels) between the border (set in "choice_node_alignment") of the dialogue frame and the questions (affectd by the "label_margin")
var choice_text_alignment : String = 'right' # Alignment of the choice's text. Can be "left" or "right"
var choice_node_alignment : String = 'right' # Alignment of the "Choice" node. Can be "left" or "right"
var previous_command : String = 'ui_up' # Input commmand for the navigating through question choices 
var next_command : String = 'ui_down' # Input commmand for the navigating through question choices
var frame_height : int = 150 # Dialog frame height (in pixels)
var frame_width : int = 700 # Dialog frame width (in pixels)
var frame_position : String = 'bottom' # Use to "top" or "bottom" to change the dialogue frame vertical alignment 
var frame_margin_vertical : int = 10 # Vertical space (in pixels) between the dialogue box and the window border
var label_margin : int = 10 # Space (in pixels) between the dialogue frame border and the text
var enable_continue_indicator : bool = true # Enable or disable the "continue_indicator" animation when the text is completely displayed. If typewritter effect is disabled it will always be visible on every dialogue block.
# END OF SETUP #


# Default values. Don't change them unless you really know what you're doing.
var id
var next_step = 'first'
var dialogue
var phrase
var phrase_raw
var current = ''
var number_characters : = 0
var dictionary

var is_question : = false
var current_choice : = 0
var number_choices : = 0

var pause_index : = 0
var paused : = false
var pause_array : = []






func _ready():
	$Timer.connect("timeout", self, "_on_Timer_timeout")
	set_frame()


func set_frame(): # Mostly aligment operations.
	match frame_position:
		"top":
			self.anchor_left = 0.5
			self.anchor_top = 0
			self.anchor_right = 0.5
			self.anchor_bottom = 0
			self.rect_position = Vector2(0, frame_margin_vertical)
		"bottom":
			print('bottom')
			self.anchor_left = 0.5
			self.anchor_top = 1
			self.anchor_right = 0.5
			self.anchor_bottom = 1
			self.rect_position = Vector2(0, -(frame_height + frame_margin_vertical))
	
	continue_indicator.anchor_left = 0.5
	continue_indicator.anchor_top = 1
	continue_indicator.anchor_right = 0.5
	continue_indicator.anchor_bottom = 1
	continue_indicator.rect_position = Vector2(-(continue_indicator.get_rect().size.x / 2) - label_margin,
			frame_height - continue_indicator.get_rect().size.y - label_margin)
	
	frame.rect_size = Vector2(frame_width, frame_height)
	frame.rect_position = Vector2(-frame_width/2, 0)
	
	label.rect_size = Vector2(frame_width - (label_margin * 2), frame_height - (label_margin * 2) )
	label.rect_position = Vector2(label_margin, label_margin)
	
	frame.hide() # Hide the dialogue frame
	continue_indicator.hide()


func initiate(file_id): # Load the whole dialogue into a variable
	id = file_id
	var file = File.new()
	file.open('%s/%s.json' % [dialogues_folder, id], file.READ)
	var json = file.get_as_text()
	dialogue = JSON.parse(json).result
	file.close()
	first() # Call the first dialogue block


func clean(): # Resets some variables to prevent errors.
	continue_indicator.hide()
	animations.stop()
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
		if progress.get(dialogues_dict).has(id): # Checks if it's the first interaction.
			update_dialogue(dialogue['repeat']) # It's not. Use the 'repeat' block.
		else:
			update_dialogue(dialogue['first']) # It is. Use the 'first' block.
			progress.get(dialogues_dict)[id] = true # Updates the singleton containing the interactions log.
	else:
			update_dialogue(dialogue['first'])


func update_dialogue(step): # step == whole dialogue block
	clean()
	current = step
	# Check what kind of interaction the block is 
	match step['type']:
		'text': # Simple text.
			not_question()
			label.bbcode_text = step['content']
			check_pauses(label.get_text())
			check_newlines(phrase_raw)
			clean_bbcode(step['content'])
			
			if step.has('next'):
				next_step = step['next']
			else:
				next_step = ''
		'divert': # Simple way to create complex dialogue trees
			not_question()
			print(step['true'])
			match step['condition']:
				'boolean':
					if progress.get(step['dictionary']).has(step['variable']):
						if progress.get(step['dictionary'])[step['variable']]:
							next_step = step['true']
						else:
							next_step = step['false']
					else:
						next_step = step['false']
				'equal':
					if progress.get(step['dictionary']).has(step['variable']):
						if progress.get(step['dictionary'])[step['variable']] == step['value']:
							next_step = step['true']
						else:
							next_step = step['false']
					else:
						next_step = step['false']
				'greater':
					if progress.get(step['dictionary']).has(step['variable']):
						if progress.get(step['dictionary'])[step['variable']] > step['value']:
							next_step = step['true']
						else:
							next_step = step['false']
					else:
						next_step = step['false']
				'less':
					if progress.get(step['dictionary']).has(step['variable']):
						if progress.get(step['dictionary'])[step['variable']] < step['value']:
							next_step = step['true']
						else:
							next_step = step['false']
					else:
						next_step = step['false']
				'range':
					if progress.get(step['dictionary']).has(step['variable']):
						if progress.get(step['dictionary'])[step['variable']] > (step['value'][0] - 1) and progress.get(step['dictionary'])[step['variable']] < (step['value'][1] + 1):
							next_step = step['true']
						else:
							next_step = step['false']
					else:
						next_step = step['false']
					
			next()
		'question': # Moved to question() function to make the code more readable.
			label.bbcode_text = step['text']
			question(step['text'], step['options'], step['next'])
			check_newlines(phrase_raw)
			clean_bbcode(step['text'])
			next_step = step['next'][0]
		'action':
			not_question()
#			if step.has('next'):
#				next_step = step['next']
				
			match step['operation']:
				'variable':
					update_variable(step['value'], step['dictionary'])
					if step.has('next'):
						next_step = step['next']
					else:
						next_step = ''
				'random':
					randomize()
					next_step = step['value'][randi() % step['value'].size()]
			
			if step.has('text'):
				label.bbcode_text = step['text']
				check_pauses(label.get_text())
				check_newlines(phrase_raw)
				clean_bbcode(step['text'])
			else:
				next()
	
	number_characters = phrase_raw.length()
	
	if wait_time > 0: # Check if the typewriter effect is active and then starts the timer.
		label.visible_characters = 0
		timer.start()
	elif enable_continue_indicator: # If typewriter effect is disabled check if the ContinueIndicator should be displayed
		continue_indicator.show()
		animations.play("Continue_Indicator")


func check_pauses(string):
	var next_search = 0
	phrase_raw = string
	next_search = phrase_raw.find('%s' % pause_char, next_search)
	
	if next_search >= 0:
		while next_search != -1:
			pause_array.append(next_search)
			phrase_raw.erase(next_search, 1)
			next_search = phrase_raw.find('%s' % pause_char, next_search)


func check_newlines(string):
	var line_search = 0
	var line_break_array = []
	var pause_array_backup = pause_array
	var new_pause_array = []
	var current_line = 0
	phrase_raw = string
	line_search = phrase_raw.find('%s' % newline_char, line_search)
	
	if line_search >= 0:
		while line_search != -1:
			line_break_array.append(line_search)
			phrase_raw.erase(line_search,1)
			line_search = phrase_raw.find('%s' % newline_char, line_search)
	
		for a in pause_array_backup.size():
			if pause_array_backup[a] > line_break_array[current_line]:
				current_line += 1
			new_pause_array.append(pause_array_backup[a]-current_line)
				
		pause_array = new_pause_array


func clean_bbcode(string):
	phrase = string
	var pause_search = 0
	var line_search = 0
	
	pause_search = phrase.find('%s' % pause_char, pause_search)
	
	if pause_search >= 0:
		while pause_search != -1:
			phrase.erase(pause_search,1)
			pause_search = phrase.find('%s' % pause_char, pause_search)
	
	phrase = phrase.split("%s" % newline_char, true, 0) # Splits the phrase using the newline_char as separator
	
	var counter = 0
	label.bbcode_text = ""
	for n in phrase:
		label.bbcode_text = label.get('bbcode_text') + phrase[counter] + '\n'
		counter += 1


func next():
	if not dialogue: # Check if is in the middle of a dialogue 
		return
	clean() # Be sure all the variables used before are restored to their default values.
	if wait_time > 0: # Check if the typewriter effect is active.
		if label.visible_characters < number_characters: # Checks if the phrase is complete.
			label.visible_characters = number_characters # Finishes the phrase.
			return # Stop the function here.
	else: # The typewriter effect is disabled so we need to make sure the text is fully displayed.
		label.visible_characters = -1 # -1 tells the RichTextLabel to show all the characters.
	
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
	check_pauses(label.get_text())
	var n = 0 # Just a looping var.
	var choice_node_align_x = 0
	
	if choice_node_alignment == "right":
		choice_node_align_x = frame_width - (choice_width + label_margin + choice_margin_horizontal)
	else:
		choice_node_align_x = label_margin + choice_margin_horizontal
	
	choices.rect_position = Vector2(choice_node_align_x,
			frame_height - ((choice_height + choice_plus_y) * options.size() + label_margin + choice_margin_vertical))
	
	for a in options:
		var choice = choice_scene.instance()
		
		if choice_text_alignment == "right":
			choice.bbcode_text = "[right]" + a + "[/right]"
		else:
			choice.bbcode_text = a
		choice.rect_size = Vector2(choice_width, choice_height)
		choices.add_child(choice)
		choices.get_child(n).rect_position.y = (choice_height + choice_plus_y) * n
		if wait_time > 0:
			choices.get_child(n).self_modulate = inactive_choice
		else:
			if n > 0:
				choices.get_child(n).self_modulate = inactive_choice
		n += 1
	
	is_question = true
	number_choices = choices.get_child_count() - 1


func change_choice(dir):
	if is_question:
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
		
#				# NOT LOOPING
#				'previous': # Not looping
#					if current_choice == 0:
#						pass
#					else:
#						choices.get_child(current_choice).self_modulate = inactive_choice
#						current_choice = current_choice - 1
#						choices.get_child(current_choice).self_modulate = active_choice
#				'next':
#					if current_choice == number_choices:
#						pass
#					else:
#						choices.get_child(current_choice).self_modulate = inactive_choice
#						current_choice = current_choice + 1
#						choices.get_child(current_choice).self_modulate = active_choice
		
			next_step = current['next'][current_choice]


func update_variable(variables_array, current_dict):
	for n in variables_array:
		progress.get(current_dict)[n[0]] = n[1]


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
		if is_question:
			choices.get_child(0).self_modulate = active_choice
		elif enable_continue_indicator:
			animations.play("Continue_Indicator")
			continue_indicator.show()
		timer.stop()
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