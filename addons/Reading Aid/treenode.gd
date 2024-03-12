@tool
extends RefCounted
class_name TreeNode


var title:String
var children:Array[TreeNode]
var level:int

#2#
var show_containers = false

func _init(node:Node, level:int = 0):
	self.level = level
	_take(node)


func _take(node:Node):
	var temp:String = ""; if "text" in node:
		temp = node.text;
	if temp.length() > 50:
		temp = temp.substr(0, 50)
	title = node.get_class() + ": " + temp
	for c in node.get_children():
		var ch:TreeNode
		if c is CodeEdit: ch = TreeNode.new(CodeEdit.new(), level+1)
		else: ch = TreeNode.new(c, level+1)
		children.append(ch)


func print_structure(show_container:bool = false):
	var text = str(level%10) + "--|".repeat(level) + title
	if !show_container and title.contains("Container"):
		text = ""
	if text != "":
		print(text)
	for c in children:
		c.print_structure(show_container)
