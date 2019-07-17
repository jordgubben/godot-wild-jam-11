extends HBoxContainer

onready var config = get_node("/root/CONFIG")
var current_img_name = ""

func _ready():
  var dialogue_node = $"./Sidebar/Dialogue"
  connect("dialogue_trigger", self, "change_image")
  dialogue_node.connect("GIFT_var_change", self, "variable_changed")
#func update_state(things):
#  # Check if this step requires a new image
#  var img_name = things
#  if img_name != null:
#    change_image(img_name)

func change_image(img_name):
  if img_name != current_img_name:
    current_img_name = img_name
    var fade_animator = $"./CenterContainer/Overlay/AnimationPlayer"
    fade_animator.play("fade_black")
  
func variable_changed(assignment):
  if assignment[0] == "inventory":
    # clear and repopulate the inventory to match inventory dictionary
    var inventory = $"./Sidebar/Inventory"
    inventory.match_dictionary()
  
func _on_AnimationPlayer_animation_finished(anim_name):
  var fade_animator = $"../../CenterContainer/Overlay/AnimationPlayer"
  var image = $"../../CenterContainer/Sprite"
  if anim_name == "fade_black":
    image.texture = load('%s/%s' % [config.locations_folder, current_img_name + "." + config.locations_img_format])
    fade_animator.play("black_0.3")
  elif anim_name == "black_0.3":
    fade_animator.play("fade_light")
  else:
    fade_animator.stop()
