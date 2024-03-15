@tool
extends HBoxContainer
class_name TopMenuButtonArray

@onready var enum_button:Button   = $enum
@onready var var_button :Button   = $var

@onready var func_button:Button   = $func_button
@onready var region_button:Button = $region_button

@onready var comment_button:Button = $comment_button
@onready var todo_button:Button = $todo

## NOTE Animation Names
const FOLD = "fold"
const UNFOLD = "unfold"


## Monitering Fold Status
var is_region_folded = false
var is_func_folded = false


func play_region_button_fold_unfold_animation():
	if is_region_folded:
		$region_button/AnimatedTextureRect.play(UNFOLD)
		$region_button.tooltip_text = "Unfold All regions"
	else:
		$region_button/AnimatedTextureRect.play(FOLD)
		$region_button.tooltip_text = "Fold All regions"


func stop_region_button_animation():
	$region_button/AnimatedTextureRect.stop()


func play_func_button_fold_unfold_animation(folded:bool = is_func_folded):
	is_func_folded = folded
	if is_func_folded: 
		$func_button/AnimatedTextureRect.play(UNFOLD)
		$func_button.tooltip_text = "Unfold All funcs"
	else:
		$func_button/AnimatedTextureRect.play(FOLD)
		$func_button.tooltip_text = "Fold All funcs"


func stop_func_button_animation():
	$func_button/AnimatedTextureRect.stop()


#region NOTE Control Signal Events

func _on_func_button_mouse_entered(): play_func_button_fold_unfold_animation()


func _on_func_button_mouse_exited(): stop_func_button_animation()
