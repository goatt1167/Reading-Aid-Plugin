@tool
extends Label
class_name Testing


# Called when the node enters the scene tree for the first time.
func _ready():
	printt(text, "is ready at", Time.get_unix_time_from_system())


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _enter_tree():
	printt(text, "enter tree", Time.get_unix_time_from_system())
