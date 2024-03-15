@tool
extends Button


func _enter_tree():
	if !pressed.is_connected(_on_pressed):
		pressed.connect(_on_pressed)


var _fold_record:Dictionary


func _on_pressed():
	var file_path = ReadingAid.script_editor.get_current_script().resource_path
	if !_fold_record.has(file_path): _fold_record[file_path] = false
	#7m# folding effects on the editor
	for i in ReadingAid.face_editor.get_line_count():	
		if ReadingAid.face_editor.is_line_code_region_start(i):
			if _fold_record[file_path]:
				ReadingAid.face_editor.unfold_line(i)
			else:
				ReadingAid.face_editor.fold_line(i)
	_fold_record[file_path] = not _fold_record[file_path]
	# change button animation

	# change update comment buttons
	get_tree().create_timer(0.05).timeout.connect(func():
		ReadingAid.global.display_comment_buttons())
	

