@tool
extends Button

var _fold_record:Dictionary

func _on_pressed():
	var file_path:String = ReadingAid.script_editor.get_current_script().resource_path
	if !_fold_record.has(file_path): _fold_record[file_path] = false
	#9m# folding effect on the editor
	for i in ReadingAid.face_editor.get_line_count():
		var line:String = ReadingAid.face_editor.get_line(i)
		var first_5_char = line.substr(0,5)
		if first_5_char == "func " or first_5_char == "stati":
			if _fold_record[file_path]:
				ReadingAid.face_editor.unfold_line(i)
			else:
				ReadingAid.face_editor.fold_line(i)
	_fold_record[file_path] = not _fold_record[file_path]
	# change button animations
	ReadingAid.face_editor.grab_focus()
	# update comment buttons because they were folded or unfolded
	get_tree().create_timer(0.01).timeout.connect(func(): #HACK display delay
		if ReadingAid.global._is_displaying_comment_buttons:
			ReadingAid.global.display_comment_buttons())



func _enter_tree():
	if !pressed.is_connected(_on_pressed):
		pressed.connect(_on_pressed)
	
