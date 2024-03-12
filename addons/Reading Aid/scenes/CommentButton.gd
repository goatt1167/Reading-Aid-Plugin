@tool
extends PanelContainer
class_name CommentButton

signal plus_button_down(int)
signal minus_button_down(int)
signal fold_unfold_down(int)
signal color_button_down(int)

var line_index:int = -1

#1g#
func get_b1_size():
	pass
	#return $hbox/rect1.size

func setup_minimum_size(length:int):
	var si = Vector2(length, length) - Vector2(4,4)
	$margin/hbox/plus_button.custom_minimum_size = si
	$margin/hbox/minus_button.custom_minimum_size = si
	$margin/hbox/fold_button.custom_minimum_size = si
	$margin/hbox/color_button.custom_minimum_size = si


func setup_color(old_color:Color, new_color:Color):
	var bg_color:Color = EditorInterface.get_editor_settings() \
	.get_setting("text_editor/theme/highlighting/background_color")
	$margin/hbox/color_button/margin/color_rect.color = bg_color.blend(new_color)
	$margin/hbox/color_button/margin/color_rect.custom_draw(bg_color.blend(old_color))

## WARNING button_up() and pressed() signal in BaseButton wouldn't send signal
## ####### but button_down() and mouse_entered() still works

func _on_plus_button_down():
	plus_button_down.emit(line_index)



func _on_minus_button_down():
	minus_button_down.emit(line_index)



func _on_fold_button_down():
	fold_unfold_down.emit(line_index)


func _on_color_button_down():
	
	color_button_down.emit(line_index)
