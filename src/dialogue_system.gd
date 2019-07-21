"""
Based on Godot Open Dialogue - Non-linear conversation system
Author: J. Sena
Version: 1.2
License: CC-BY
URL: https://jsena42.bitbucket.io/god/
Repository: https://bitbucket.org/jsena42/godot-open-dialogue/
"""

extends Control

signal GIFT_var_change

##### SETUP #####

var choice_scene = load('res://Choice.tscn') # Base scene for choices
## Required nodes ##
onready var frame : Node = $Frame # The container node for the dialogues.
onready var label : Node = $Frame/RichTextLabel # The label where the text will be displayed.
onready var choices : Node = $Frame/Choices # The container node for the choices.
onready var timer : Node = $Timer # Timer node.
onready var continue_indicator : Node = $ContinueIndicator # Blinking square displayed when the text is all printed.
onready var animations : Node = $AnimationPlayer # Animates blinking continue indicator
## Typewriter effect ##
var wait_time : float = 0.02 # Time interval (in seconds) for the typewriter effect. Set to 0 to disable it. 
var pause_time : float = 2.0 # Duration of each pause when the typewriter effect is active.
var pause_char : String = '|' # The character used in the JSON file to define where pauses should be. If you change this you'll need to edit all your dialogue files.
var newline_char : String = '@' # The character used in the JSON file to break lines. If you change this you'll need to edit all your dialogue files.
## Other customization options ##
onready var progress = PROGRESS # The AutoLoad script where the interaction log, quest variables, inventory and other useful data should be accessible.
onready var config = CONFIG
var blocks_seen = 'blocks_seen' # The dictionary on 'progress' used to keep track of interactions.
var choice_plus_y : int = 4 # How much space (in pixels) should be added between the choices (affected by 'choice_height').
var active_choice_color : Color = Color(1.0, 1.0, 1.0, 1.0)
var inactive_choice_color : Color = Color(1.0, 1.0, 1.0, 0.4)
var choice_height : int = 20 # Choice label's height
var choice_width : int = 250 # Choice label's width
var choice_margin_vertical : int = 10 # Vertical space (in pixels) between the bottom border of the dialogue frame and the last question (affectd by the 'label_margin')
var choice_margin_horizontal : int = 10 # Horizontal space (in pixels) between the border (set in 'choice_node_alignment') of the dialogue frame and the questions (affectd by the 'label_margin')
var previous_command : String = 'ui_up' # Input commmand for the navigating through question choices
var next_command : String = 'ui_down' # Input commmand for the navigating through question choices
var continue_dialogue : String = 'ui_continue'
var frame_height : int = 325 # Dialog frame height (in pixels)

var label_margin : int = 20 # Space (in pixels) between the dialogue frame border and the text
var enable_continue_indicator : bool = true # Enable or disable the 'continue_indicator' animation when the text is completely displayed. If typewritter effect is disabled it will always be visible on every dialogue block.

# END OF SETUP #

# Default values. Don't change them unless you really know what you're doing.
var current_dialogue_name
var new_dialogue_name
var next_block_name = ''
var dialogue
var current_img_name = ''
var phrase = ''
var phrase_raw = ''
var current_block = ''
var number_characters : = 0

var is_question : = false
var current_choice : = 0
var number_choices : = 0

var pause_index : = 0
var paused : = false
var pause_array : = []

func _ready():
#warning-ignore:return_value_discarded
  timer.connect('timeout', self, '_on_Timer_timeout')
  frame.show()
  clean_text_ui()

func go_to_block(file_id, block_name = 'first'):
  new_dialogue_name = file_id
  next_block_name = block_name
  load_next_block()
  while not current_block.has("content"):
    go_to_next_block() # process "instant" blocks
  update_text_ui()

func continue_to_next_content_block():
  go_to_next_block()
  while not current_block.has("content"):
    go_to_next_block() # process "instant" blocks
  update_text_ui()

func go_to_next_block():
  set_next_dialogue_and_block_ids()
  load_next_block()

func set_next_dialogue_and_block_ids():
  # first set next_block_name and possibly new_dialogue_name
  if is_question:
    evaluate_choice()
  else:
    if typeof(current_block["next"]) == TYPE_ARRAY:
      new_dialogue_name = current_block["next"][0]
      next_block_name = current_block["next"][1]
    else: # single value, the name of the next block
      next_block_name = current_block["next"]

# Set new block name and possibly new dialogue name.
func evaluate_choice():
  var options_available = filter_options(current_block['options'])
  var opt_array = options_available[current_choice]
  # Depending on the number of elements in the array, we may switch to a different dialogue
  if len(opt_array) == 2: # Move to block within this dialogue
    next_block_name = opt_array[1]
  elif len(opt_array) == 3: # Switch dialogue
    new_dialogue_name = opt_array[1]
    next_block_name = opt_array[2]
      
# Some fields that a block may have and their effect:
# - set_var:    Sets one or more variables before anything else happens
# - condition:  Evaluate the condition and set current_block depending on outcome.
# - content:    If absent we continue to the next block without waiting for player input.
#               May be helpful as an in-between block for setting a variable
#               if the actual next-block should not always set this variable.
# - content_repeat: displayed if content is present and the block is visited for the Nth>1st time.
# - options:    An array of 2- or 3-element arrays that define options from which
#               the player must choose.

func load_next_block():
  if new_dialogue_name != null and new_dialogue_name != current_dialogue_name:
    dialogue = load_dialogue(new_dialogue_name) # sets current_dialogue_name and dialogue
  # Continue to the next block
  current_block = dialogue[next_block_name]
  current_block.id = current_dialogue_name + ":" + next_block_name
  if current_block.has("set_var"):
    set_variables(current_block["set_var"])  
  while current_block.has("condition"): # drill down to a non-conditional block
    var condition_outcome = condition_outcome(current_block)
    var outcome_block
    if typeof(condition_outcome) == TYPE_STRING:
      outcome_block = dialogue[condition_outcome]
    elif typeof(condition_outcome) == TYPE_ARRAY and len(condition_outcome) == 2:
      # [dialogue_id, block_name]
      dialogue = load_dialogue(condition_outcome[0])
      outcome_block = dialogue[condition_outcome[1]]
    elif typeof(condition_outcome) == TYPE_DICTIONARY:
      outcome_block = condition_outcome
      if condition_holds(current_block["condition"]):
        outcome_block.id = current_block.id + ":true"
      else:
        outcome_block.id = current_block.id + ":false"
    current_block = outcome_block
    if current_block.has("set_var"):
      set_variables(current_block["set_var"]) 
  is_question = false
  if current_block.has("options"):
    is_question = true

func condition_outcome(obj):
  if condition_holds(obj["condition"]):
    return obj.get("true")
  else:
    return obj.get("false")

func condition_holds(condition, value_to_match = true):
  if typeof(condition) == TYPE_STRING:
    # var_name or dict_name<separator>var_name
    var dict_and_var = condition.split(config.condition_separator)
    if len(dict_and_var) == 1: # use default "variables" dictionary
      return progress.get("variables").get(condition, false) == value_to_match
    elif len(dict_and_var) == 2: # dictionary is specified
      return progress.get(dict_and_var[0]).get(dict_and_var[1], false) == value_to_match
  elif typeof(condition) == TYPE_DICTIONARY:
    return condition_holds(condition["var_id"], condition["value"])
  elif typeof(condition) == TYPE_ARRAY: # multiple conditions
    for subcondition in condition:
      if not condition_holds(subcondition):
        return false
    return true

func filter_options(proto_options):
  var real_options = []
  for protopt in proto_options:
    if typeof(protopt) == TYPE_ARRAY:
      real_options.append(protopt)
    elif typeof(protopt) == TYPE_DICTIONARY:
      var conditional = condition_holds(protopt["condition"])
      if conditional and protopt.has("true"):
        real_options.append(protopt["true"])
      elif not conditional and protopt.has("false"):
        real_options.append(protopt["false"])
    else:
      print("ERROR: option has unexpected type " + str(typeof(protopt)))
  return real_options

func load_dialogue(file_id):
  # Load new dialogue
  current_dialogue_name = file_id
  var file = File.new()
  file.open('%s/%s.json' % [config.dialogues_folder, current_dialogue_name], file.READ)
  var json = file.get_as_text()
  file.close()
  var parsed_json = JSON.parse(json)
  if len(parsed_json.get("error_string")) > 0:
    print(parsed_json["error_string"])
    print("Error on line " + str(parsed_json["error_line"]))
  dialogue = parsed_json.result
  return dialogue

func set_variables(assignment_arrays):
  for assignment in assignment_arrays:
    if len(assignment) == 2: # default variables array
      progress.get("variables")[assignment[0]] = assignment[1]
      emit_signal("GIFT_var_change", ["variables", assignment[0], assignment[1]])
    else: # assignment = [dictionary, key, value]
      progress.get(assignment[0])[assignment[1]] = assignment[2]
      emit_signal("GIFT_var_change", assignment)

func update_text_ui():
  clean_text_ui() # Be sure all the variables used before are restored to their default values.
  var text_idx
  if current_block.has('content_repeat'):
    if progress.get(blocks_seen).has(current_block.id): # Checks if it's the first interaction with this block.
      text_idx = "content_repeat" # It's not. Use the 'repeat' text.
    else:
      progress.get(blocks_seen)[current_block.id] = true # Updates the singleton containing the interactions log.
      text_idx = "content" # It is. Use the 'content' text.
  else:
    text_idx = "content"
  number_characters = 0 # Resets the count
  label.bbcode_text = current_block[text_idx]
  if current_block.has("options"):
    question(filter_options(current_block['options']))
  else:
    check_pauses(label.get_text())
  check_newlines(phrase_raw)
  clean_bbcode(current_block[text_idx])
  number_characters = phrase_raw.length()
  if wait_time > 0: # Check if the typewriter effect is active and then starts the timer.
    label.visible_characters = 0
    timer.start()
  elif enable_continue_indicator: # If typewriter effect is disabled check if the ContinueIndicator should be displayed
    continue_indicator.show()
    animations.play('Continue_Indicator')

func question(options):
  check_pauses(label.get_text())
  var n = 0 # Just a looping var.
  var choice_node_align_x = label_margin + choice_margin_horizontal  
  choices.rect_position = Vector2(choice_node_align_x,
      frame_height - ((choice_height + choice_plus_y) * options.size() + label_margin + choice_margin_vertical))
  var total_choices_height = 0
  for option in options:
    var option_text
    if typeof(option) == TYPE_ARRAY: # simple [text, next] option
      option_text = option[0]
    elif typeof(option) == TYPE_DICTIONARY: # conditional option
      var conditional_option = condition_outcome(option)
      option_text = conditional_option[0]
    var choice = choice_scene.instance()
    choice.set_text(option_text)
#    choice.rect_size = Vector2(choice_width, choice_height)
    choices.add_child(choice)
    choices.get_child(n).rect_position.y = total_choices_height
    total_choices_height += (choice.get_line_height() + choice.get_constant("line_spacing")) * choice.get_line_count() + choice_plus_y
    if wait_time > 0:
      choices.get_child(n).self_modulate = inactive_choice_color
    else:
      if n > 0:
        choices.get_child(n).self_modulate = inactive_choice_color
    n += 1
  number_choices = choices.get_child_count() - 1

func clean_text_ui(): # Resets some variables to prevent errors.
  continue_indicator.hide()
  animations.stop()
  paused = false
  pause_index = 0
  pause_array = []
  current_choice = 0
  timer.wait_time = wait_time # Resets the typewriter effect delay

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
  pause_search = phrase.find('%s' % pause_char, pause_search)
  if pause_search >= 0:
    while pause_search != -1:
      phrase.erase(pause_search,1)
      pause_search = phrase.find('%s' % pause_char, pause_search)
  # Splits the phrase using the newline_char as separator
  phrase = phrase.split('%s' % newline_char, true, 0)
  var counter = 0
  label.bbcode_text = ''
  for n in phrase:
    label.bbcode_text = label.get('bbcode_text') + phrase[counter] + '\n'
    counter += 1

func update_pause():
  if pause_array.size() > (pause_index+1): # Check if the current pause is not the last one. 
    pause_index += 1
  else: # Doesn't have any pauses left.
    pause_array = []
    pause_index = 0
    
  paused = false
  timer.wait_time = wait_time
  timer.start()

func change_choice(dir):
  if is_question:
    if label.visible_characters >= number_characters: # Make sure the whole question is displayed before the player can answer.
      match dir:    
        'previous': # Looping
          choices.get_child(current_choice).self_modulate = inactive_choice_color
          current_choice = current_choice - 1 if current_choice > 0 else number_choices
          choices.get_child(current_choice).self_modulate = active_choice_color
        'next':
          choices.get_child(current_choice).self_modulate = inactive_choice_color
          current_choice = current_choice + 1 if current_choice < number_choices else 0
          choices.get_child(current_choice).self_modulate = active_choice_color

func maybe_complete_text_animation():
  if wait_time > 0: # Check if the typewriter effect is active.
    if label.visible_characters < number_characters: # Checks if the phrase is complete.
      label.visible_characters = number_characters # Finishes the phrase.
      return true
  label.visible_characters = -1 # -1 tells the RichTextLabel to show all the characters.
  label.bbcode_text = ''
  if choices.get_child_count() > 0: # If has choices, remove them.
    for n in choices.get_children():
      choices.remove_child(n)
  return false  

func _input(event): # This function can be easily replaced. Just make sure you call the function using the right parameters.
  if event.is_action_pressed('%s' % previous_command):
    change_choice('previous')
  if event.is_action_pressed('%s' % next_command):
    change_choice('next')
  if event.is_action_pressed('%s' % continue_dialogue):
    if maybe_complete_text_animation():
      return # this "continue" is only used to show all text
    continue_to_next_content_block()

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
      choices.get_child(0).self_modulate = active_choice_color
    elif dialogue and enable_continue_indicator:
      animations.play('Continue_Indicator')
      continue_indicator.show()
    timer.stop()
    return
