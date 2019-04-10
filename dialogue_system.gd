"""
Godot Open Dialogue - Non-linear conversation system
Author: J. Sena
Version: 1.2
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
onready var sprite_left : Node = $SpriteLeft # Used for showing the avatar on the dialogue
onready var sprite_right : Node = $SpriteRight
onready var name_left : Node = $Frame/NameLeft
onready var name_right : Node = $Frame/NameRight
## Typewriter effect ##
var wait_time : float = 0.02 # Time interval (in seconds) for the typewriter effect. Set to 0 to disable it. 
var pause_time : float = 2.0 # Duration of each pause when the typewriter effect is active.
var pause_char : String = '|' # The character used in the JSON file to define where pauses should be. If you change this you'll need to edit all your dialogue files.
var newline_char : String = '@' # The character used in the JSON file to break lines. If you change this you'll need to edit all your dialogue files.
## Other customization options ##
onready var progress = PROGRESS # The AutoLoad script where the interaction log, quest variables, inventory and other useful data should be acessible.
var dialogues_dict = 'dialogues' # The dictionary on 'progress' used to keep track of interactions.
var choice_plus_y : int = 2 # How much space (in pixels) should be added between the choices (affected by 'choice_height').
var active_choice : Color = Color(1.0, 1.0, 1.0, 1.0)
var inactive_choice : Color = Color(1.0, 1.0, 1.0, 0.4)
var choice_height : int = 20 # Choice label's height
var choice_width : int = 250 # Choice label's width
var choice_margin_vertical : int = 10 # Vertical space (in pixels) between the bottom border of the dialogue frame and the last question (affectd by the 'label_margin')
var choice_margin_horizontal : int = 10 # Horizontal space (in pixels) between the border (set in 'choice_node_alignment') of the dialogue frame and the questions (affectd by the 'label_margin')
var choice_text_alignment : String = 'right' # Alignment of the choice's text. Can be 'left' or 'right'
var choice_node_alignment : String = 'right' # Alignment of the 'Choice' node. Can be 'left' or 'right'
var previous_command : String = 'ui_up' # Input commmand for the navigating through question choices 
var next_command : String = 'ui_down' # Input commmand for the navigating through question choices
var frame_height : int = 150 # Dialog frame height (in pixels)
var frame_width : int = 900 # Dialog frame width (in pixels)
var frame_position : String = 'bottom' # Use to 'top' or 'bottom' to change the dialogue frame vertical alignment 
var frame_margin_vertical : int = 10 # Vertical space (in pixels) between the dialogue box and the window border
var label_margin : int = 20 # Space (in pixels) between the dialogue frame border and the text
var enable_continue_indicator : bool = true # Enable or disable the 'continue_indicator' animation when the text is completely displayed. If typewritter effect is disabled it will always be visible on every dialogue block.
var sprite_offset : Vector2 = Vector2(30, 0) # Used for polishing avatars' position. Can use negative values.
var name_offset : Vector2 = Vector2(-10, -15) # Offsets the name labels relative to the frame borders.
var show_names : bool = true # Turn on and off the character name labels
# END OF SETUP #


# Default values. Don't change them unless you really know what you're doing.
var id
var next_step = ''
var dialogue
var phrase = ''
var phrase_raw = ''
var current = ''
var number_characters : = 0
var dictionary

var is_question : = false
var current_choice : = 0
var number_choices : = 0

var pause_index : = 0
var paused : = false
var pause_array : = []






#
onready var sprite_timer : Node = $SpriteTimer
onready var tween : Node = $Tween

var white_opaque = Color(1.0, 1.0, 1.0, 1.0)
var white_transparent = Color(1.0, 1.0, 1.0, 0.0)
var black_opaque = Color(0.0, 0.0, 0.0, 1.0)
var black_transparent = Color(0.0, 0.0, 0.0, 0.0)
var light_gray_opaque = Color(0.75, 0.75, 0.75, 1.0)

var mirrored_sprite = 'right'

var shake_base = 20
var move_distance = 100
var ease_in_speed = 0.25
var ease_out_speed = 0.50

var characters_folder = 'res://img/characters'
var characters_image_format = 'png'

var previous_pos
var sprite

var on_tween = false

var shake_amount

var shake_weak = 1
var shake_regular = 2
var shake_strong = 4

var shake_short = 0.25
var shake_medium = 0.5
var shake_long = 2

var on_animation : bool = false

var avatar_left : String = ''
var avatar_right : String = ''

var shaking : bool = false

func _ready():
	set_physics_process(true)
	timer.connect('timeout', self, '_on_Timer_timeout')
	sprite_timer.connect('timeout', self, '_on_Sprite_Timer_timeout')
	set_frame()


func _physics_process(delta):
	if shaking:
		sprite.offset = Vector2(rand_range(-1.0, 1.0) * shake_amount, rand_range(-1.0, 1.0) * shake_amount)
	pass


func set_frame(): # Mostly aligment operations.
	match frame_position:
		'top':
			self.anchor_left = 0.5
			self.anchor_top = 0
			self.anchor_right = 0.5
			self.anchor_bottom = 0
			self.rect_position = Vector2(0, frame_margin_vertical)
		'bottom':
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
	
	sprite_left.modulate = white_transparent
	sprite_right.modulate = white_transparent
	
	
	name_left.hide()
#	name_left.position = 'left'
	name_left.rect_position.y = name_offset.y
	
	name_right.hide()
#	name_right.position = 'right'
	name_right.rect_position.y = name_offset.y


func initiate(file_id, block = 'first'): # Load the whole dialogue into a variable
	id = file_id
	var file = File.new()
	file.open('%s/%s.json' % [dialogues_folder, id], file.READ)
	var json = file.get_as_text()
	dialogue = JSON.parse(json).result
	file.close()
	first(block) # Call the first dialogue block

#func start_from(file_id, block): # Similar to 

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


func first(block):
	frame.show()
	if block == 'first': # Check if we are going to use the default 'first' block
		if dialogue.has('repeat'):
			if progress.get(dialogues_dict).has(id): # Checks if it's the first interaction.
				update_dialogue(dialogue['repeat']) # It's not. Use the 'repeat' block.
			else:
				progress.get(dialogues_dict)[id] = true # Updates the singleton containing the interactions log.
				update_dialogue(dialogue['first']) # It is. Use the 'first' block.
		else:
				update_dialogue(dialogue['first'])
	else: # We are going to use a custom first block
		update_dialogue(dialogue[block])


func update_dialogue(step): # step == whole dialogue block
	clean()
	current = step
	number_characters = 0 # Resets the counter
	# Check what kind of interaction the block is
	match step['type']:
		'text': # Simple text.
			not_question()
			label.bbcode_text = step['content']
			check_pauses(label.get_text())
			check_newlines(phrase_raw)
			clean_bbcode(step['content'])
			number_characters = phrase_raw.length()
			check_animation(step)
			check_names(step)
			
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
			check_animation(step)
			check_names(step)
			number_characters = phrase_raw.length()
			next_step = step['next'][0]
			
		'action':
			not_question()
			
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
				number_characters = phrase_raw.length()
				check_animation(step)
				check_names(step)
			else:
				label.visible_characters = number_characters
				next()
	
	if wait_time > 0: # Check if the typewriter effect is active and then starts the timer.
		label.visible_characters = 0
		timer.start()
	elif enable_continue_indicator: # If typewriter effect is disabled check if the ContinueIndicator should be displayed
		continue_indicator.show()
		animations.play('Continue_Indicator')


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
	
	phrase = phrase.split('%s' % newline_char, true, 0) # Splits the phrase using the newline_char as separator
	
	var counter = 0
	label.bbcode_text = ''
	for n in phrase:
		label.bbcode_text = label.get('bbcode_text') + phrase[counter] + '\n'
		counter += 1


func next():
	if not dialogue or on_animation: # Check if is in the middle of a dialogue 
		return
	clean() # Be sure all the variables used before are restored to their default values.
	if wait_time > 0: # Check if the typewriter effect is active.
		if label.visible_characters < number_characters: # Checks if the phrase is complete.
			label.visible_characters = number_characters # Finishes the phrase.
			return # Stop the function here.
	else: # The typewriter effect is disabled so we need to make sure the text is fully displayed.
		label.visible_characters = -1 # -1 tells the RichTextLabel to show all the characters.
	
	if next_step == '': # Doesn't have a 'next' block.
		if current.has('animation_out'):
			animate_sprite(current['position'], current['avatar'], current['animation_out'])
			yield(tween, "tween_completed")
		else:
			sprite_left.modulate = white_transparent
			sprite_right.modulate = white_transparent
		dialogue = null
		name_left.hide()
		name_right.hide()
		frame.hide() 
		avatar_left = ''
		avatar_right = ''
	else:
		label.bbcode_text = ''
		if choices.get_child_count() > 0: # If has choices, remove them.
			for n in choices.get_children():
				choices.remove_child(n)
		else:
			pass
		if current.has('animation_out'):
			animate_sprite(current['position'], current['avatar'], current['animation_out'])
			yield(tween, "tween_completed")
		
		update_dialogue(dialogue[next_step])


func check_names(block):
	if not show_names:
		return
	if block.has('name'):
		if block['position'] == 'left':
			name_left.text = block['name']
			yield(get_tree(), 'idle_frame')
			name_left.rect_size.x = 0
			name_left.rect_position.x += name_offset.x
			name_left.set_process(true)
			name_left.show()
			name_right.hide()
		else:
			name_right.text = block['name']
			
			yield(get_tree(), 'idle_frame')
			name_right.rect_size.x = 0
			name_right.rect_position.x = frame_width - name_right.rect_size.x - name_offset.x
			name_right.set_process(true)
			name_right.show()
			name_left.hide()
	else:
		pass


func check_animation(block):
	reset_sprites()
	if block.has('avatar'):
		if block.has('animation_in'):
			animate_sprite(block['position'], block['avatar'], block['animation_in'])
	else:
		return


func reset_sprites():
	sprite_left.position = Vector2(-(frame_width - (sprite_left.get_rect().size.x / 2) - sprite_offset.x) / 2, -(frame_height + (sprite_left.get_rect().size.y / 2) - sprite_offset.y) / 2)
	sprite_right.position = Vector2((frame_width - (sprite_right.get_rect().size.x / 2) - sprite_offset.x) / 2, -(frame_height + (sprite_left.get_rect().size.y / 2) - sprite_offset.y) / 2)


func animate_sprite(direction, image, animation):
	var current_pos
	var move_vector
	
	if direction == 'left':
		sprite = sprite_left
		current_pos = sprite.position
		
		move_vector = Vector2(current_pos.x - move_distance, current_pos.y)
	else:
		sprite = sprite_right
		current_pos = sprite.position
		
		move_vector = Vector2(current_pos.x + move_distance, current_pos.y)
	
	previous_pos = current_pos
	
	match animation:
		
		'shake_weak_short':
			shake_amount = shake_weak
			sprite_timer.wait_time = shake_short
			sprite_timer.start()
			on_animation = true
			shaking = true
			set_physics_process(true)
			
		'shake_weak_medium':
			shake_amount = shake_weak
			sprite_timer.wait_time = shake_medium
			sprite_timer.start()
			on_animation = true
			shaking = true
			set_physics_process(true)
			
		'shake_weak_long':
			shake_amount = shake_weak
			sprite_timer.wait_time = shake_long
			sprite_timer.start()
			on_animation = true
			shaking = true
			set_physics_process(true)
			
		'shake_regular_short':
			shake_amount = shake_regular
			sprite_timer.wait_time = shake_short
			sprite_timer.start()
			on_animation = true
			shaking = true
			set_physics_process(true)
			
		'shake_regular_medium':
			shake_amount = shake_regular
			sprite_timer.wait_time = shake_medium
			sprite_timer.start()
			on_animation = true
			shaking = true
			set_physics_process(true)
			
		'shake_regular_long':
			shake_amount = shake_regular
			sprite_timer.wait_time = shake_long
			sprite_timer.start()
			on_animation = true
			shaking = true
			set_physics_process(true)
			
		'shake_strong_short':
			shake_amount = shake_strong
			sprite_timer.wait_time = shake_short
			sprite_timer.start()
			on_animation = true
			shaking = true
			set_physics_process(true)
			
		'shake_strong_medium':
			shake_amount = shake_strong
			sprite_timer.wait_time = shake_medium
			sprite_timer.start()
			on_animation = true
			shaking = true
			set_physics_process(true)
			
		'shake_strong_long':
			shake_amount = shake_strong
			sprite_timer.wait_time = shake_long
			sprite_timer.start()
			on_animation = true
			shaking = true
			set_physics_process(true)
			
		'fade_in':
			load_image(sprite, image)
			tween.interpolate_property(sprite, 'modulate',
					white_transparent, white_opaque, ease_in_speed/1.25,
					Tween.TRANS_QUAD, Tween.EASE_IN)
					
			sprite_timer.wait_time = ease_in_speed/1.25
			tween.start()
			sprite_timer.start()
			on_animation = true
			
		'fade_out':
			tween.interpolate_property(sprite, 'modulate',
					white_opaque, white_transparent, ease_out_speed/1.25,
					Tween.TRANS_QUAD, Tween.EASE_OUT)
					
			sprite_timer.wait_time = ease_out_speed/1.25
			tween.start()
			sprite_timer.start()
			on_animation = true
			
		'move_in':
			load_image(sprite, image)
			tween.interpolate_property(sprite, 'position',
					move_vector, current_pos, ease_in_speed,
					Tween.TRANS_QUINT, Tween.EASE_IN)
					
			tween.interpolate_property(sprite, 'modulate',
					white_transparent, white_opaque, ease_in_speed,
					Tween.TRANS_QUINT, Tween.EASE_IN)
					
			sprite_timer.wait_time = ease_in_speed
			tween.start()
			sprite_timer.start()
			on_animation = true
			
		'move_out':
			tween.interpolate_property(sprite, 'position',
					current_pos, move_vector, ease_out_speed,
					Tween.TRANS_BACK, Tween.EASE_OUT)
					
			tween.interpolate_property(sprite, 'modulate',
					white_opaque, black_transparent, ease_out_speed,
					Tween.TRANS_QUINT, Tween.EASE_OUT)
					
			sprite_timer.wait_time = ease_out_speed
			tween.start()
			sprite_timer.start()
			on_animation = true
		
		'on':
			tween.interpolate_property(sprite, 'modulate',
					light_gray_opaque, white_opaque, ease_in_speed,
					Tween.TRANS_QUAD, Tween.EASE_IN)
					
			sprite_timer.wait_time = ease_in_speed
			tween.start()
			sprite_timer.start()
			on_animation = true
			
		'off':
			tween.interpolate_property(sprite, 'modulate',
					white_opaque, light_gray_opaque, ease_out_speed,
					Tween.TRANS_QUAD, Tween.EASE_OUT)
					
			sprite_timer.wait_time = ease_out_speed
			tween.start()
			sprite_timer.start()
			on_animation = true


func load_image(sprite, image):
	sprite.texture = load('%s/%s' % [characters_folder, image])


func question(text, options, next):
	check_pauses(label.get_text())
	var n = 0 # Just a looping var.
	var choice_node_align_x = 0
	
	if choice_node_alignment == 'right':
		choice_node_align_x = frame_width - (choice_width + label_margin + choice_margin_horizontal)
	else:
		choice_node_align_x = label_margin + choice_margin_horizontal
	
	choices.rect_position = Vector2(choice_node_align_x,
			frame_height - ((choice_height + choice_plus_y) * options.size() + label_margin + choice_margin_vertical))
	
	for a in options:
		var choice = choice_scene.instance()
		
		if choice_text_alignment == 'right':
			choice.bbcode_text = '[right]' + a + '[/right]'
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
			match dir: # If you want to stop the 'loop' effect on the choices, invert the commented sections.
		
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
		elif dialogue and enable_continue_indicator:
			animations.play('Continue_Indicator')
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


func _on_Sprite_Timer_timeout():
	sprite.position = previous_pos
	set_physics_process(false)
	on_animation = false
	shaking = false