@tool
extends PanelContainer
class_name BottomButtonArray

@onready var enum_button:Button = $margin/hbox/enum
@onready var var_button:Button  = $margin/hbox/var
@onready var todo_button:Button = $margin/hbox/todo
@onready var func_button:Button = $margin/hbox/func_button
@onready var region_button:Button = $margin/hbox/region_button
@onready var comment_button:Button = $margin/hbox/comment_button



## DOC configure theme related to Editor's settings
func configure_button_theme():
	var line_height = ReadingAid.EDITOR_LINE_HEIGHT
	custom_minimum_size.y = line_height * 2
	
	#6 buttons' margins
	var margin:int = line_height*1.6/10
	$margin/hbox.add_theme_constant_override("separation", margin)
	$margin.add_theme_constant_override("margin_bottom", margin)
	$margin.add_theme_constant_override("margin_top", margin)
	$margin.add_theme_constant_override("margin_left", margin)
	$margin.add_theme_constant_override("margin_right", margin)
	
	#6 buttons' font color
	enum_button.add_theme_color_override("font_color", ReadingAid.EDITOR_KEYWORD_COLOR)
	var_button.add_theme_color_override("font_color", ReadingAid.EDITOR_KEYWORD_COLOR)
	todo_button.add_theme_color_override("font_color", ReadingAid.EDITOR_WARNING_COLOR)
	func_button.add_theme_color_override("font_color", ReadingAid.EDITOR_KEYWORD_COLOR)
	region_button.add_theme_color_override("font_color", ReadingAid.EDTIOR_COMMENT_COLOR)
	comment_button.add_theme_color_override("font_color", ReadingAid.EDITOR_DOC_COLOR)

	#4 buttons' font size  
	# manually estimate display_scale because editor provides a wrong value
	# HACK 1pt font size = 1.3333 pixel
	# 15pt font size = 20 pixel ish??
	# It's a legitmate math, not really a hack
	var display_scale = (line_height - ReadingAid.EDITOR_LINE_SPACING) \
		/ (4.0/3.0) / ReadingAid.EDITOR_CODE_FONT_SIZE
	var font_size = ceil((ReadingAid.EDITOR_CODE_FONT_SIZE) * display_scale)
	enum_button.theme.set_font_size("font_size", "Button", font_size)



func configure_button_state():
	# update UI
	var line_height = ReadingAid.EDITOR_LINE_HEIGHT
	size = Vector2.ZERO # remove size
	custom_minimum_size.y = line_height * 2 # remove min size
	
	$margin/hbox/back.disabled = ReadingAid.global.keyword_last_clicked == []





const _FOLD_ANIMATION_NAME:String = "fold"
const _UNFOLD_AMIMATION_NAME:String = "unfold"

var is_func_folded = false
func play_func_button_fold_unfold_animation():
	if is_func_folded:
		$margin/hbox/func_button/animation.play(_UNFOLD_AMIMATION_NAME)
	else:
		$margin/hbox/func_button/animation.play(_FOLD_ANIMATION_NAME)

func stop_func_button_animation():
	$margin/hbox/func_button/animation.stop()



var is_region_folded = false
func play_region_button_fold_unfold_animation():
	if is_region_folded:
		$margin/hbox/region_button/animation.play(_UNFOLD_AMIMATION_NAME)
	else:
		$margin/hbox/region_button/animation.play(_FOLD_ANIMATION_NAME)

func stop_region_button_animation():
	$margin/hbox/region_button/animation.stop()


func _on_back_pressed():
	ReadingAid.global.go_back()
