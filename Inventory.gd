extends Control

func _ready():
  pass

func update_inventory(dictionary):
  clear_inventory()
  for item in dictionary.keys():
    if dictionary[item]:
      # Create richtextlabel to hold item text
      var new_item = RichTextLabel.new()
      new_item.text = item
      new_item.rect_min_size = Vector2(100, 15)
      new_item.scroll_active = false
      $"./Items".add_child(new_item)
      
func clear_inventory():
  var inventory = $"./Items"
  var items = inventory.get_children()
  for i in items:
    inventory.remove_child(i)
    i.queue_free()