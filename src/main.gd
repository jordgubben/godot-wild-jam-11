extends Control

export(String) var starting_timeline = "rags"
export(String) var starting_location = "hall"

var location_graph = {}


func _ready():
  location_graph = create_location_graph("./src/location_graph.json")
  $"./UI/Sidebar/Dialogue".go_to_block(starting_timeline + "/" + starting_location)
  

func create_location_graph(filename):  
  var file = File.new()
  file.open(filename, file.READ)
  var json = file.get_as_text()
  location_graph = JSON.parse(json).result
  file.close()