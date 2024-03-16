@tool
extends PanelContainer
class_name CommentButton


var line_index:int = -1

var editor:CodeEdit: 
	get: return ReadingAid.face_editor

#1g
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


## DOC grow one line of bg color below the comment at line_index
func _on_plus_button_down():
	print("+")
	# extract minmax, encode, and color_char
	var string = editor.get_line(line_index)
	var minmax = ScriptExtractor.get_color_encode_range(string)
	var encode = string.substr(minmax[0], minmax[1]-minmax[0]+1)
	var color_char = ScriptExtractor.color_char_from_encode(encode)
	var prefix = "#" if encode[1] != "#" else "##"
	# grow
	encode = encode.to_int() + 1;
	encode = min(encode, Settings.MAX_COMMENT_BG_COLOR_LINE_COUNT)
	encode = prefix + str(encode) + color_char + "#"
	#replace
	string = string.erase(minmax[0], minmax[1]-minmax[0]+1)
	string = string.insert(minmax[0], encode)
	editor.set_line(line_index, string)
	ReadingAid.global.update_comment_bg_colors(line_index, line_index+1)


## DOC remove one line of bg color below the comment at line_index
func _on_minus_button_down():
	# extract code
	editor = ReadingAid.face_editor
	var string = editor.get_line(line_index)
	var minmax = ScriptExtractor.get_color_encode_range(string)
	var encode = string.substr(minmax[0], minmax[1]-minmax[0]+1)
	var color_char = ScriptExtractor.color_char_from_encode(encode)
	var prefix = "#" if encode[1] != "#" else "##"
	# shrink
	var height:int = encode.to_int() - 1; if height < 1: height = 1
	encode = prefix + str(height) + color_char + "#"
	#replace
	string = string.erase(minmax[0], minmax[1]-minmax[0]+1)
	string = string.insert(minmax[0], encode)
	editor.set_line(line_index, string)
	
	var extra = ScriptExtractor.extra_comment_lines(ReadingAid.face_editor, line_index)
	ReadingAid.global.update_comment_bg_colors(line_index, (line_index+1)+extra+(height+1))


## DOC region tags for custom region fold/unfold [constant ReadingAid.CUSTOM_REGION_START_TAG]
const CUSTOM_REGION_START_TAG  = "customregiontagstart"
const CUSTOM_REGION_END_TAG    = "customregiontagend"
const DEFAULT_REGION_START_TAG = "region"
const DEFAULT_REGION_END_TAG   = "endregion"




## DOC fold / unfold the custom comment encode
## HACK this func is full of hack. custom fold is achieved by manipulating
## region tags with the unwanted side effect of undo-redo space polution
func _on_fold_button_down():
	if editor.is_line_folded(line_index):
		editor.unfold_line(line_index)
		# after fold/unfold altering line positions, re-display buttons to correct position
		# HACK for some reason, _display_comment_buttons can't use new button positions,
		# but use old positions. But the new position does come through 0.00001s after.
		# To safely get the new position, a 0.1s delayed update is used.
		get_tree().create_timer(0.05).timeout.connect(ReadingAid.global.display_comment_buttons)
		return
	#4i# make sure the last line is empty, which is necessary for region tags.
	var maxi = editor.get_line_count()
	if editor.get_line(maxi-1).strip_edges() != "":
		editor.insert_line_at(maxi-1, "")
		editor.swap_lines(maxi-1, maxi)
	var string = editor.get_line(line_index)
	var minmax:Array[int] = ScriptExtractor.get_color_encode_range(string)
	var comment_line_count = 1 + ScriptExtractor.extra_comment_lines(editor, line_index)
	var code_line_count:int = string.to_int()
	var color_line_count = comment_line_count + code_line_count
	# insert region tags (!! last line is guarenteed empty)
	editor.set_code_region_tags(CUSTOM_REGION_START_TAG, CUSTOM_REGION_END_TAG)
	editor.insert_line_at(line_index, "#"+CUSTOM_REGION_START_TAG)
	editor.insert_line_at(line_index+color_line_count, "#"+CUSTOM_REGION_END_TAG)
	editor.fold_line(line_index)
	# reset tags
	# WARNING upon deleting line in region, region doesn't shrink size
	# it'll just take an innocent line as extra to fill up the missing space
	# the first line won't eat innocent lines, because it's technically outside the region
	editor.set_code_region_tags(DEFAULT_REGION_START_TAG, DEFAULT_REGION_END_TAG)
	editor.set_caret_column(0, false);
	editor.set_caret_line(max(line_index-1,0), false)
	editor.remove_text(line_index+color_line_count, 0, line_index+color_line_count+1, 0)
	editor.remove_text(line_index, 0, line_index+1, 0)
	# after fold/unfold altering line positions, re-display buttons to correct position
	# HACK for some reason, _display_comment_buttons can't use new button positions,
	# but use old positions. But the new position does come through 0.00001s after.
	# To safely get the new position, a 0.1s delayed update is used.
	get_tree().create_timer(0.05).timeout.connect(ReadingAid.global.display_comment_buttons)


func _on_color_button_down():
	var string = editor.get_line(line_index)
	var minmax = ScriptExtractor.get_color_encode_range(string)
	var encode = string.substr(minmax[0], minmax[1]-minmax[0]+1)

	var new_color_char = ScriptExtractor.next_color_char_from_encode(encode)

	#5d manipulate the string
	var prefix = "##" if encode[1] == "#" else "#"
	var number = encode.to_int()
	var new_encode = prefix + str(number) + new_color_char

	string = string.erase(minmax[0], minmax[1]-minmax[0]+1).insert(minmax[0], new_encode)
	
	#4i find the button (_color_comment_line_numbers and _buttons indices match)
	var button_index
	for i in ReadingAid.color_comment_line_numbers.size():
		if ReadingAid.color_comment_line_numbers[i] == line_index:
			button_index = i
	var new_new_color_char = ScriptExtractor.next_color_char_from_encode(new_encode)
	var old_color:Color = ScriptExtractor.color_from_char(new_color_char)
	var new_color:Color = ScriptExtractor.color_from_char(new_new_color_char)
	ReadingAid.shared_comment_button_pool[button_index].setup_color(old_color, new_color)
		
	editor.set_line(line_index, string) # string that contains new color char
	ReadingAid.global.update_comment_bg_colors(line_index, line_index+1)
