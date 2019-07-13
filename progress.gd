extends Node

# If you already have an AutoLoad script where you keep track of the player progress, you can just add there the code below and edit the 'progress' var in the DialogueSystem.gd file.

var dialogues = { # Everytime the player talks with an NPC it will be stored here so the system use the "repeat" block (if available) on the next interaction.
#	'question': true # This is here just for demonstration (and debugging) pourposes.
}

# Misc game state
var variables = {
	# What timeline the player is currenlty in
	'timeline': "rags" # Alt: 'rags', 'riches', 'ruins'
  }

# Map of what passages between locations have open rifts
# (Only keeps track of existance, not involved timelines)
var rifts = {
	"hall+living_room": true
}