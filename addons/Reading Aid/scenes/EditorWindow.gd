@tool
extends Window
class_name EditorWindow

## NOTE UI component
var windowed_editor:CodeEdit

## NOTE signal
signal go_to_line(int)

## NOTE store line number -> line number 
## [editor line] > [parent line]
var _line_lookup:Array[int] 

## NOTE temp
var _mouse_start_point:Vector2
var _window_start_point:Vector2
var _current_mouse_position:Vector2

enum Tab { VAR = 1, TODO = 2, ENUM = 3 }
var _active_tab:Tab
var _all_tabs:Array[Tab] = [Tab.VAR, Tab.TODO, Tab.ENUM]


var is_closed:bool:
	get: return !visible
	set(value): pass
	
var is_open:bool:
	get: return visible
	set(value): pass


var _now:float: 
	get: 
		return Time.get_unix_time_from_system()



var _has_theme = false
func configure_theme():
	# performance improvement because this func will be called repeatedly
	if _has_theme: return 
	
	# real configuration starts
	# clone settings
	windowed_editor = $panel/vbox/panel2/CodeEdit
	var target:CodeEdit = \
		EditorInterface.get_script_editor().get_current_editor().get_base_editor()
	for property in target.get_property_list():
		var property_name = property["name"]
		var value = target.get(property_name)
		windowed_editor.set(property_name, value)
	
	# custom setting
	windowed_editor.editable = false
	windowed_editor.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	windowed_editor.gutters_draw_breakpoints_gutter = false
	windowed_editor.caret_draw_when_editable_disabled = true
	windowed_editor.placeholder_text = " [placeholder text : it seems there is nothing to see]"
	windowed_editor.context_menu_enabled = true
	windowed_editor.add_theme_color_override ("font_readonly_color", Color(0.875, 0.875, 0.875, 1))
	$panel/vbox/panel1/hbox/tab/enum.add_theme_color_override("font_color", ReadingAid.EDITOR_KEYWORD_COLOR)
	$panel/vbox/panel1/hbox/tab/var.add_theme_color_override("font_color", ReadingAid.EDITOR_KEYWORD_COLOR)
	$panel/vbox/panel1/hbox/tab/todo.add_theme_color_override("font_color", ReadingAid.EDITOR_WARNING_COLOR)

	
	# custom context menu
	var menu:PopupMenu = windowed_editor.get_menu()
	menu.item_count = menu.get_item_index(TextEdit.MENU_SELECT_ALL) + 1
	menu.remove_item(0)
	menu.remove_item(1)

	_has_theme = true



func _process(delta):
	# UI move windows along with cursor 
	if should_move_along_cursor:
		if not Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
		#if no button? => stop it
			should_move_along_cursor = false # setting changed in setter
		elif _mouse_start_point == Vector2.ZERO:
		#if new? => anchor the starting point if just clicked
			# moving window can't give static mouse position
			# self.mouse_position will cause window to glitch blink
			# [parent] is "root" window, whatever that is
			# BUG: unfixable on Mac
			# if press ESC while dragging, it remembers the "right button down" state
			# the next time the window is open. It's magic bug.
			_current_mouse_position = get_parent().get_mouse_position()
			_mouse_start_point = _current_mouse_position
			_window_start_point = position
		else:
		#if ongoing? => move according to anchor point
			position = _window_start_point + \
				(get_parent().get_mouse_position() - _mouse_start_point)
	
	# UI prevent closing window too fast
	if _now - context_menu_timestamp > 0.2 and Input.is_key_pressed(KEY_ESCAPE):
		close()
		return
	
	# Signal (NOTE signal receiver will close the window)
	if should_emit_line > -1:
		go_to_line.emit(should_emit_line)
		should_emit_line = -1
		return
	
	# WARNING somehow? [windowed_editor] becomes null when after [close()]?
	if windowed_editor == null or windowed_editor.visible == false: return
	# ####### code below needs to guarentee [windowed_editor != null]
	
	# UI change cursor shape & right click cursor behavior
	if is_ctrl_meta_held_down:
		if not Input.is_action_pressed(ReadingAid.META_CTRL):
			is_ctrl_meta_held_down = false
			windowed_editor.mouse_default_cursor_shape = Control.CURSOR_IBEAM
		else:
			windowed_editor.mouse_default_cursor_shape = Control.CURSOR_HELP
	elif _is_mouse_over_text():
		windowed_editor.mouse_default_cursor_shape = Control.CURSOR_IBEAM
		windowed_editor.caret_move_on_right_click = true
	else:
		windowed_editor.mouse_default_cursor_shape = Control.CURSOR_DRAG
		windowed_editor.caret_move_on_right_click = false
	
	# UI record context menu timestamp
	if windowed_editor.is_menu_visible():
		context_menu_timestamp = _now


## NOTE signal bridges from _input() to _process()
var should_emit_line:= -1
var is_ctrl_meta_held_down:= false
var should_move_along_cursor:= false:
	get: return should_move_along_cursor
	set(value):
		should_move_along_cursor = value
		windowed_editor.caret_draw_when_editable_disabled = !should_move_along_cursor
		windowed_editor.context_menu_enabled = !should_move_along_cursor
		_mouse_start_point = Vector2.ZERO


func _input(event):
	# [ctrl/meta] + [left click]
	if Input.is_action_pressed(ReadingAid.META_CTRL):
		is_ctrl_meta_held_down = true # signal
		if event is InputEventMouseButton && event.button_index == MOUSE_BUTTON_LEFT:
			var mouse_pos = windowed_editor.get_local_mouse_pos()
			var ln = windowed_editor.get_line_column_at_pos(mouse_pos, true).y
			var lln = _line_lookup[ln]
			should_emit_line = lln # signal
	
	if Input.is_action_just_pressed(ReadingAid.TAB):
		var index = _all_tabs.find(_active_tab) + 1
		if index == _all_tabs.size(): index = 0
		_display_tab(_all_tabs[index])
	
	# [away from selection] + [right click]
	if !_is_mouse_over_text() and event is InputEventMouseButton \
		and event.button_index == MOUSE_BUTTON_RIGHT:
		should_move_along_cursor = true # setting changed in setter
	
	if _is_mouse_over_text():
		if windowed_editor.has_selection():
			windowed_editor.get_menu().set_item_text(0, "Copy")
		else:
			windowed_editor.get_menu().set_item_text(0, "Copy Line")
	# WARNING it won't stop following cursor inside _input() because it doesn't detect button up.
	# ####### need to do it in process.



func _is_mouse_over_text() -> bool:
	var pos = windowed_editor.get_local_mouse_pos()
	var line_num = windowed_editor.get_line_column_at_pos(pos, true).y
	var column_max = windowed_editor.get_line(line_num).length()
	if column_max == 0: return false
	var max_x = windowed_editor.get_pos_at_line_column(line_num, column_max-1).x
	# comparing column position - compensation
	return max_x >= pos.x - windowed_editor.get_gutter_width(0) * 2 



## NOTE Timestamps to prevent instant re-act
var context_menu_timestamp:= -1.0
var display_timestamp:= -1.0


var _source_editor:CodeEdit
var _extract:Array[Array]
## NOTE pop up the window and display given Array[Array[Line]] blocks
func popup_and_display_face_editor(tab:Tab):
	if _now - display_timestamp < 0.4: return # prevent instant re-open
	
	if visible: # to unparent before being used again
		visible = false 

	visible = true
	# TODO resizable setting by removing [Borderless] flag
	EditorInterface.popup_dialog_centered_ratio(self, 0.55)
	
	_source_editor = ReadingAid.face_editor
	_display_tab(tab)

	# set caret position
	var line_num = ReadingAid.face_editor.get_caret_line()
	var index = 0
	for i in _line_lookup.size():
		if _line_lookup[i] >= line_num:
			index = i; break
	windowed_editor.set_caret_line(index, true)
	
	$panel/vbox/panel1/hbox/file_name_label.text = \
		ReadingAid.script_editor.get_current_script().resource_path.get_file()

	grab_focus()




## NOTE close the popup window
func close():
	display_timestamp = _now
	visible = false


func _set_active_tab(tab:Tab):
	_active_tab = tab
	var panel:PanelContainer
	for ch in $panel/vbox/panel1/hbox/tab.get_children():
		if ch.get_children().size() > 0:
			panel = ch.get_child(0)
	
	if tab == Tab.ENUM:
		panel.reparent($panel/vbox/panel1/hbox/tab/enum, false)
	elif tab == Tab.VAR:
		panel.reparent($panel/vbox/panel1/hbox/tab/var, false)
	elif tab == Tab.TODO:
		panel.reparent($panel/vbox/panel1/hbox/tab/todo, false)




func _display_tab(tab:Tab):
	windowed_editor.grab_focus()
	_set_active_tab(tab)
	
	if tab == Tab.ENUM:
		_extract = ScriptExtractor.extract_enums(_source_editor)
	elif tab == Tab.VAR: 
		_extract = ScriptExtractor.extract_vars(_source_editor)
	elif tab == Tab.TODO: 
		_extract = ScriptExtractor.extract_todos(_source_editor)
	
	#21m# display the content
	var total_line = 0
	for block in _extract: total_line += block.size()
	total_line += _extract.size() * 2
	
	var strings:PackedStringArray = PackedStringArray()
	strings.resize(total_line)
	_line_lookup.resize(total_line)
	
	var index = 0
	var extract_block_index = 0
	var block:Array[Line]
	while extract_block_index < _extract.size():
		block = _extract[extract_block_index]
		for line in block:
			strings[index] = line.text
			_line_lookup[index] = line.line_number
			index += 1
		index += 2
		extract_block_index += 1
	
	windowed_editor.text = "\n".join(strings)
