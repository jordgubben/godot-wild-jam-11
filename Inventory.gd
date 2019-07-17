extends Control

var child_dict = {}
var items_node

func _ready():
  items_node = $"./VBoxContainer/Items"

func add_item(name):

  var new_item_node = RichTextLabel.new()
  new_item_node.text = name
  new_item_node.rect_min_size = Vector2(250, 20)
  items_node.add_child(new_item_node)
  child_dict[name] = new_item_node

func remove_item(name):
  var to_remove = child_dict.get(name)
  if to_remove == null:
    print("ERROR: trying to remove item that is not in inventory!")
    get_tree().quit()
  else:
    items_node.remove_child(to_remove)
    child_dict.erase(name)
    
func match_dictionary():
  # first clear all children, then repopulate
  var item_nodes = items_node.get_children()
  for it in item_nodes:
    items_node.remove_child(it)
  var items = PROGRESS.get("inventory")
  print(items)
  for item in items.keys():
    if items[item]:
      add_item(item)