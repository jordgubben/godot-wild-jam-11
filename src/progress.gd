extends Node

# If you already have an AutoLoad script where you keep track of the player progress, you can just add there the code below and edit the 'progress' var in the DialogueSystem.gd file.

var blocks_seen = { # Everytime the player talks with an NPC it will store a conversation block that passed if it had a "content_repeat" field, so the system uses this on the next interaction.
#	'question': true # This is here just for demonstration (and debugging) pourposes.
}

var inventory = {
  # stuff the player has that is shown in the inventory panel.  
}

# Misc game state, this is the default dictionary
var variables = {
  # Locks
  'frontdoor_locked': true,

  # Rifts
  "study=>dining_room": true,

  # What timeline the player is currenlty in
  'timeline': "rags" # Alt: 'rags', 'riches', 'ruins',
}

# Map of what passages between locations have open rifts
# (Only keeps track of existance, not involved timelines)
var rifts = {
  "hall+living_room": true
}