"""
var  or var_button
enum or enum_button
todo or todo_button
"""

@tool
extends Button


func _on_pressed():
	var file_name = ReadingAid.script_editor.get_current_script().resource_path.get_file()
	var tab:EditorWindow.Tab
	if   name.contains("var") : tab = EditorWindow.Tab.VAR
	elif name.contains("todo"): tab = EditorWindow.Tab.TODO
	elif name.contains("enum"): tab = EditorWindow.Tab.ENUM
	ReadingAid.popup_window.popup_and_display_face_editor(tab)
	


func _enter_tree():
	if !pressed.is_connected(_on_pressed):
		pressed.connect(_on_pressed)
