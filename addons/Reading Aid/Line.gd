extends RefCounted
class_name Line

var text       := ""
var line_number:= -1

func _init(text:String="", line_num:int=-1):
	self.text = text
	self.line_number = line_num
