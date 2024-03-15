@tool
extends Button


func _enter_tree():
	if pressed.is_connected(_on_pressed) == false:
		pressed.connect(_on_pressed)


func _on_pressed():
	ReadingAid.is_comment_color_mode_on = !ReadingAid.is_comment_color_mode_on
	ReadingAid.global.update_comment_bg_onscreen()
	ReadingAid.face_editor.grab_focus()
