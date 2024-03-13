@tool
extends EditorPlugin
class_name ReadingAid

var CommentButtonScene = preload("res://addons/Reading Aid/scenes/CommentButton.tscn")

## Convennient References
var script_editor:ScriptEditor = EditorInterface.get_script_editor()
var face_editor:CodeEdit # the current base_editor in the front


## Custom Buttons & Window
var top_menu_button_array:TopMenuButtonArray
var editor_button_array:BottomButtonArray # INFO connec to face_editor
var popup_window:EditorWindow
## an array of comment buttons shared by different base_editors
## CAUTION every opened scripts have their own base_editor,
## ####### and they are all open at the same time. When a button
## ####### is added as face_editor's child, it won't be usable
## ####### by another base_editor even when its parent is out of sight.
## ####### Need to manually manage the shared buttons on hide.
var _shared_comment_button_pool:Array[CommentButton] = [] # INFO connect to face_editor


## get current time
var _now:float:
	get: return Time.get_unix_time_from_system()
	set(v): pass




## get current editor's theme's bg color
var _default_editor_bg_color:Color:
	get:
		assert(face_editor!=null, "var _default_editor_bg_color: face_editor == null")
		return face_editor.get_theme_color("background_color")
	set(v): pass


##1# regex to search for comments' color encode
var head_space_encode_regex:RegEx

##1# initial signal setup signals for face_editor and its ScriptEditorBase parent.
## 1. face_editor's "exit" signal needs to disconnect children in _button_pool
## 2. ScriptEditorBase "script_changed" signal needs to re-color comment bg
## 3. face_editor's "text_change" signal to update bg color more readily
func _editor_signal_initial_setup():
	assert(script_editor.get_current_editor() != null \
	and script_editor.get_current_editor().get_base_editor() != null,
	 "_active_editor_signal_setup(): delayed_init() should assure those are not null.")
	# validation signal, to re-color after parser coloring
	if !script_editor.get_current_editor().edited_script_changed.is_connected(_update_comment_bg_onscreen):
		script_editor.get_current_editor().edited_script_changed.connect(_update_comment_bg_onscreen)
	# exiting signal, to free button_pool from exisint parent
	if !face_editor.tree_exiting.is_connected(_remove_child_buttons):
		face_editor.tree_exiting.connect(_remove_child_buttons.bind(face_editor))
	# text_changed signal, to update bg color more readiy
	if !face_editor.text_changed.is_connected(_on_editor_text_changed):
		face_editor.text_changed.connect(_on_editor_text_changed)
	if !face_editor.resized.is_connected(_display_and_update_bottom_button_array):
		face_editor.resized.connect(_display_and_update_bottom_button_array)

##1# cleanup when face_editor is about to exit scene tree.
func _remove_child_buttons(editor:CodeEdit):
	for b in _shared_comment_button_pool:
		if editor.get_children().has(b): editor.remove_child(b)
	if editor.get_children().has(editor_button_array): editor.remove_child(editor_button_array)


##1#
func _enter_tree():
	if !script_editor.editor_script_changed.is_connected(_on_changing_active_script):
		script_editor.editor_script_changed.connect(_on_changing_active_script)
	if !EditorInterface.get_editor_settings().settings_changed.is_connected(_get_editor_settings):
		EditorInterface.get_editor_settings().settings_changed.connect(_get_editor_settings)
	#7m# setup delayed init
	# WARNING set_process() is ignored before _ready()
	# pause _process() and _input() using _init_completed bridge signal
	var _init_completed = false 
	if _delay_init_timer == null:
		_delay_init_timer = Timer.new()
		_delay_init_timer.one_shot = true
		add_child(_delay_init_timer)
		_delay_init_timer.timeout.connect(_delayed_init)
	# _delay_init_timer will be used in _delayed_init()
	_delayed_init()



##1#
func _exit_tree():
	#2m# free buttons in menu bar
	script_editor.get_child(0).get_child(0).remove_child(top_menu_button_array)
	top_menu_button_array.free()
	# reset bg color to nil
	for i in face_editor.get_line_count():
		_set_line_background_color(i, _default_editor_bg_color)
	#3m# free buttons in face_editor
	face_editor.get_children().clear()
	for b in _shared_comment_button_pool: b.free(); _shared_comment_button_pool = []
	editor_button_array.free()



##1# DOC plugin life cycle (like _enter_tree)
## Upon arriving at new script
## 1. hook face_editor's exit_tree signal
## 2. face_editor connect to _shared_comment_button_pool
func _on_changing_active_script(_script:Script):
	#1m# WARNING in IDE startup, there will be several times of script_changed signal
	# they will call script_editor.get_current_editor().get_base_editor() in this func
	# when it's still null. Use _init_completed to block the proceeding
	if !_init_completed: return
	face_editor = script_editor.get_current_editor().get_base_editor()
	_editor_signal_initial_setup()
	
	#5m# INFO connect _shared_comment_button_pool to new face_editor
	for b in _shared_comment_button_pool:
		# set free old parent
		if b.get_parent() != null: b.get_parent().remove_child(b)
		# set up new parent
		face_editor.add_child(b)
	if editor_button_array.get_parent() != null:
		editor_button_array.get_parent().remove_child(editor_button_array)
	face_editor.add_child(editor_button_array)
	
	_hide_bottom_button_array()
	_hide_comment_buttons()



##1# signal bridge to pause _process(), _input() and _on_change_script()
var _init_completed = false
var _delay_init_timer:Timer
##1# the setup to be delayed until the script_editor gets its editors open
## WARNING the plugin enter the tree before the IDE has CodeEdit editor ready.
## Many func that uses face_editor will print error because it's null.
## The HACK here is to delay the setup until script_editor has CodeEdit ready.
## The delayed setup is used to setup anything that uses face_editor
func _delayed_init():
	if script_editor.get_current_editor() != null \
	and script_editor.get_current_editor().get_base_editor() != null:
		face_editor = script_editor.get_current_editor().get_base_editor()
		# get setting values first
		
		_get_editor_settings()
		
		_editor_signal_initial_setup()
		_setup_hotkey()
		_init_setup_top_menu_button_array()
		# initial setup
		# WARNING scripts are opened around 0.2s after _ready().
		# WARNING system default CodeEdit won't be available until later
		# WARNING popup_window's theme can't be configured until then
		# WARNING _ready() happens before EditorInterface compplete its setup,
		# WARNING causing problem in popup_window's startup.
		_init_setup_popup_window_after_face_editor()
		_init_setup_bottom_button_array_after_face_editor()
		# setup regex
		var color_palette_string = "".join(Settings.PALETTE.keys())
		head_space_encode_regex = RegEx.new()
		head_space_encode_regex.compile("^\\s*#{1,2}[0-9]+[" + color_palette_string + "]{0,1}#")
		# complete setup
		_init_completed = true
	else:
		_delay_init_timer.start(0.5)


##3# setup hotkey
const E = &"E Key"
const META_CTRL = &"META/CTRL Key"
const TAB = &"TAB Key"
func _setup_hotkey(): # NOTE hot keys are available for other classes too.
	if InputMap.has_action(E): InputMap.erase_action(E)
	var event_e = InputEventKey.new(); event_e.keycode = KEY_E
	InputMap.add_action(E)
	InputMap.action_add_event(E, event_e)
	
	if InputMap.has_action(META_CTRL): InputMap.erase_action(META_CTRL)
	InputMap.add_action(META_CTRL)
	var event_meta = InputEventKey.new(); event_meta.keycode = KEY_META
	var event_ctrl = InputEventKey.new(); event_ctrl.keycode = KEY_CTRL
	InputMap.action_add_event(META_CTRL, event_meta)
	InputMap.action_add_event(META_CTRL, event_ctrl)
	
	if InputMap.has_action(TAB): InputMap.erase_action(TAB)
	InputMap.add_action(TAB)
	var event_tab = InputEventKey.new(); event_tab.keycode = KEY_TAB
	InputMap.action_add_event(TAB, event_tab)


##1#
func _init_setup_top_menu_button_array():
	top_menu_button_array = preload("res://addons/Reading Aid/scenes/TopMenuButtonArray.tscn").instantiate()
	# make sure button enters tree before connecting signals
	script_editor.get_child(0).get_child(0).add_child(top_menu_button_array)
	top_menu_button_array.move_to_front()
	top_menu_button_array.enum_button.pressed.connect(_enum_button_pressed)
	top_menu_button_array.var_button.pressed.connect(_var_button_pressed)
	top_menu_button_array.func_button.pressed.connect(_func_button_pressed.bind(top_menu_button_array))
	top_menu_button_array.region_button.pressed.connect(_region_button_pressed.bind(top_menu_button_array))
	top_menu_button_array.todo_button.pressed.connect(_todo_button_pressed)
	top_menu_button_array.comment_button.pressed.connect(_comment_button_pressed)
	

##1#
func _init_setup_bottom_button_array_after_face_editor():
	editor_button_array = preload("res://addons/Reading Aid/scenes/BottomButtonArray.tscn").instantiate()
	face_editor.add_child(editor_button_array)
	editor_button_array.move_to_front()
	editor_button_array.enum_button.pressed.connect(_enum_button_pressed)
	editor_button_array.var_button.pressed.connect(_var_button_pressed)
	editor_button_array.func_button.pressed.connect(_func_button_pressed.bind(editor_button_array))
	editor_button_array.region_button.pressed.connect(_region_button_pressed.bind(editor_button_array))
	editor_button_array.todo_button.pressed.connect(_todo_button_pressed)
	editor_button_array.comment_button.pressed.connect(_comment_button_pressed)
	_hide_bottom_button_array()




##1#
func _init_setup_popup_window_after_face_editor():
	popup_window = preload("res://addons/Reading Aid/scenes/EditorWindow.tscn").instantiate()
	popup_window.configure_theme()
	
	popup_window.set_unparent_when_invisible(true)
	popup_window.visible = false
	
	popup_window.close_requested.connect(popup_window.close)
	popup_window.focus_exited.connect(popup_window.close)
	popup_window.go_to_line.connect(go_to_line)



static var EDITOR_LINE_HEIGHT:float
static var EDITOR_ERROR_BG_COLOR:Color
static var EDITOR_KEYWORD_COLOR:Color
static var EDITOR_WARNING_COLOR:Color
static var EDTIOR_COMMENT_COLOR:Color
static var EDITOR_DOC_COLOR:Color
static var EDITOR_CODE_FONT_SIZE:float
static var EDITOR_LINE_SPACING:float
func _get_editor_settings():
	if popup_window != null: popup_window.configure_theme()
	EDITOR_LINE_HEIGHT = face_editor.get_line_height()
	EDITOR_ERROR_BG_COLOR = EditorInterface.get_editor_settings().get_setting \
		("text_editor/theme/highlighting/mark_color")
	EDITOR_KEYWORD_COLOR = EditorInterface.get_editor_settings().get_setting \
		("text_editor/theme/highlighting/keyword_color")
	EDITOR_WARNING_COLOR = EditorInterface.get_editor_settings().get_setting \
		("text_editor/theme/highlighting/comment_markers/warning_color")
	EDTIOR_COMMENT_COLOR = EditorInterface.get_editor_settings().get_setting \
		("text_editor/theme/highlighting/comment_color")
	EDITOR_DOC_COLOR = EditorInterface.get_editor_settings().get_setting \
		("text_editor/theme/highlighting/doc_comment_color")
	EDITOR_CODE_FONT_SIZE = EditorInterface.get_editor_settings().get_setting \
		("interface/editor/code_font_size")
	EDITOR_LINE_SPACING = EditorInterface.get_editor_settings().get_setting \
		("text_editor/appearance/whitespace/line_spacing")



##1#
func _input(event:InputEvent):
	if !_init_completed: return
	if Input.is_action_pressed(META_CTRL):
		if Input.is_action_pressed(E):
			if popup_window.is_closed:
				_enum_button_pressed(false)
		
		_should_display_comment_buttons = true
	


var script_extraction:Array[Array] = [] # temp storage for script extraction

##1t# DOC pressed => summon popup window displaying enums
func _enum_button_pressed(follow_mouse:bool = true):
	face_editor.grab_focus()
	var file_name = script_editor.get_child(0).get_child(0).get_children().filter(
		func(x): if x is Label: return x)[0].text
	popup_window.popup_and_display(file_name, face_editor, EditorWindow.Tab.ENUM, \
		follow_mouse, face_editor.get_caret_line())


##1t# DOC pressed => summon popup window displaying vars
func _var_button_pressed(follow_mouse:bool = true):
	face_editor.grab_focus()
	var file_name = script_editor.get_child(0).get_child(0).get_children().filter(
		func(x): if x is Label: return x)[0].text
	popup_window.popup_and_display(file_name, face_editor, EditorWindow.Tab.VAR, \
		follow_mouse, face_editor.get_caret_line())


##1t# DOC pressed => summon popup window displaying todos
func _todo_button_pressed(follow_mouse:bool = true):
	face_editor.grab_focus()
	var file_name = script_editor.get_child(0).get_child(0).get_children().filter(
		func(x): if x is Label: return x)[0].text
	popup_window.popup_and_display(file_name, face_editor, EditorWindow.Tab.TODO, \
		follow_mouse, face_editor.get_caret_line())


##1t# DOC record region fold states
var regions_folded: = false
##1t# DOC pressed => fold / unfold all regions
func _region_button_pressed(button_array):
	#7m# folding effects on the editor
	for i in face_editor.get_line_count():	
		if face_editor.is_line_code_region_start(i):
			if regions_folded:
				face_editor.unfold_line(i)
			else:
				face_editor.fold_line(i)
	regions_folded = not regions_folded
	# change button animation
	face_editor.grab_focus()
	top_menu_button_array.is_region_folded = regions_folded
	editor_button_array.is_region_folded = regions_folded
	button_array.play_region_button_fold_unfold_animation()



##1t# DOC record func fold states
var funcs_folded: =false
##1t# DOC pressed => fold / unfold all funcs
func _func_button_pressed(button_array):
	#9m# folding effect on the editor
	for i in face_editor.get_line_count():
		var line:String = face_editor.get_line(i)
		var first_5_char = line.substr(0,5)
		if first_5_char == "func " or first_5_char == "stati":
			if funcs_folded:
				face_editor.unfold_line(i)
			else:
				face_editor.fold_line(i)
	funcs_folded = not funcs_folded
	# change button animations
	face_editor.grab_focus()
	top_menu_button_array.is_func_folded = funcs_folded
	editor_button_array.is_func_folded = funcs_folded
	button_array.play_func_button_fold_unfold_animation()


##1t# DOC record if comment color mode is on
var is_comment_color_mode_on:bool = true
##1t# DOC pressed => turn on / off the comment color mode
func _comment_button_pressed():
	face_editor.grab_focus()
	is_comment_color_mode_on = !is_comment_color_mode_on
	_update_comment_bg_colors(0, face_editor.get_line_count())


##1t# DOC move caret and viewport to new caret location
## NOTE this method is exclusively used by popup_window
func go_to_line(num:int):
	face_editor.set_caret_line(num)
	face_editor.center_viewport_to_caret()
	popup_window.close()


func _hide_bottom_button_array():
	editor_button_array.visible = false
func _display_and_update_bottom_button_array():
	# siz & pos
	editor_button_array.setup_UI_component()
	editor_button_array.position = face_editor.size - editor_button_array.size
	editor_button_array.position.x *= 0.97 # adjustment
	editor_button_array.position.y *= 0.97 # adjustment
	editor_button_array.visible = true
	var mouse_pos = face_editor.get_local_mouse_position()
	if Rect2(Vector2.ZERO, face_editor.size).has_point(mouse_pos):
		if mouse_pos.y + EDITOR_LINE_HEIGHT < editor_button_array.position.y:
			editor_button_array.position.y = mouse_pos.y + EDITOR_LINE_HEIGHT



var _temp_caret_line_index:int
var _text_changed_timestamp:float
const TEXT_CHANGE_COOLDOWN:float = 0.5
func _on_editor_text_changed():
	# when typing continuously, update happens
	if _now - _text_changed_timestamp > TEXT_CHANGE_COOLDOWN:
		_temp_caret_line_index = face_editor.get_caret_line()
		# if caret is typing in comment
		if face_editor.is_in_comment(_temp_caret_line_index) >= 0: 
			_update_comment_bg_colors(_temp_caret_line_index, _temp_caret_line_index+1)
		_text_changed_timestamp = _now


func _process(delta):
	if !_init_completed: return
	#if face_editor == null: return # when no active script is open, halt process.
	
	if is_comment_color_mode_on:
		_cooldown += delta
		if _cooldown > Settings.COMMENT_BG_COLOR_UPDATE_COOLDOWN:
			if _latest_updated_screen_range != _get_onscreen_line_index_range_and_stretch():
				_update_comment_bg_onscreen()
			_cooldown = 0
		
		#10i# receive signal and display comment buttons
		if _should_display_comment_buttons:
			if !_is_displaying_comment_buttons:
				_display_comment_buttons()
				_display_and_update_bottom_button_array()
			_is_displaying_comment_buttons = true
			if Input.is_action_just_released(META_CTRL):
				_should_display_comment_buttons = false
		else:
			if _is_displaying_comment_buttons:
				_hide_comment_buttons()
				_hide_bottom_button_array()
				_is_displaying_comment_buttons = false


## remember latest screen range being updated
var _latest_updated_screen_range:Array[int] = [0,0]


func _update_comment_bg_onscreen():
	var minmax = _get_onscreen_line_index_range_and_stretch()
	_latest_updated_screen_range = minmax
	if minmax == []: return # this occurs when all files are closed in editor
	_update_comment_bg_colors(minmax[0], minmax[1])


## bridge signal for when CTRL-META is held down
var _should_display_comment_buttons = false
var _is_displaying_comment_buttons = false
var _color_comment_line_numbers:Array[int] = []
## tell _process() to update bg color immdediately
func _should_update_comment_bg_color_immediately():
	_cooldown = Settings.COMMENT_BG_COLOR_UPDATE_COOLDOWN


func _set_line_background_color(index:int, c:Color):
	# avoid overriding error marker's bg red color
	if face_editor.get_line_background_color(index) != EDITOR_ERROR_BG_COLOR:
		face_editor.set_line_background_color(index, c)

##1r# DOC draw bg color for comments based on lines
## 1. find special comment tags and store them
## 2. update bg color according to tags
## WARNING this method will be called extensively, must be optimized
func _update_comment_bg_colors(from_line:int, to_line:int):
	#4g# if setting says no color, remove all color
	if is_comment_color_mode_on == false:
		for i in face_editor.get_line_count():
			_set_line_background_color(i, _default_editor_bg_color)
		return

	if face_editor == null: face_editor = script_editor.get_current_editor().get_base_editor()
	#0g# get active updating range
	var mini:= from_line
	var maxi:= to_line
	var editor_line_count:= face_editor.get_line_count()
	if maxi == -1 or maxi >= editor_line_count: maxi = editor_line_count

	var color_char:String; var color:Color; var num:int
	#1g# signal bridge to be processed by other methods
	_color_comment_line_numbers = [] 
	
	#2g#- to avoid color pollution, bg color needs to be pre-cleaned
	#   - bg is being purged constantly by Parser's parsing
	#   - don't intervene with parser's error marks, leave red markers alone
	for i in range(mini, maxi):
		_set_line_background_color(i, _default_editor_bg_color)
	
	# draw color based on encodes
	for i in range(mini, maxi):
		var line = face_editor.get_line(i)
		var res = head_space_encode_regex.search(line)
		if res: # found qualified comments
			_color_comment_line_numbers.append(i) # signal bridge
			var tempstring = res.get_string().strip_edges()
			color_char = _extract_color_char_from_encode(tempstring)
			color = _get_color_from_char(color_char)
			num = tempstring.to_int() + _how_many_extra_comment_lines(i)
			for j in range (i, min(editor_line_count, (num+1)+i )):
				_set_line_background_color.call(j, color)



##1r# DOC Sometimes, the returned char is a valid key in palette, sometimes, it's not
## WARNING When it's not a valid key, the invald chars should be a number.
func _extract_color_char_from_encode(encode:String) -> String:
	_assert_valid_encode(encode)
	var char = encode[-2]
	if "0123456789".contains(char): return ""
	return char


##1r# DOC in palette, find the char next to the one provided in the encode
func _extract_next_color_char_from_encode(encode:String) -> String:
	var color_char = _extract_color_char_from_encode(encode)
	var keys = Settings.PALETTE.keys()
	# in case of not found, find would be -1, next would be 0, perfect
	var next_index = keys.find(color_char) + 1;
	#2m# if next_index is out of bound, return an invalid color char
	if next_index == keys.size(): return ""
	return keys[next_index]


##1r# get color from palette corresponding to the given char
## WARNING the parameter char can be an invalid key in palette.
## Use dictionary's default parameter
func _get_color_from_char(color_char:String) -> Color:
	return Settings.PALETTE.get(color_char, Settings.PLACEHOLDER_COLOR)


func _assert_valid_encode(encode:String):
	var res = head_space_encode_regex.search(encode)
	assert(res!=null and res.get_string().strip_edges() == encode,
	"func _assert_valid_encode: bad comment encoding: \"" + encode + "\"")


## Count extra comments. Emphasis is on extra, meaning starting from line 2 of the comment section
func _how_many_extra_comment_lines(line_index:int):
	var index = line_index+1
	var count = 0
	while index < face_editor.get_line_count():
		if face_editor.is_in_comment(index) >= 0: count += 1
		else: break
		index += 1
	return count


# cooldown enforced between every 2 updates of comments' bg color
var _cooldown:float = 0.0






## to record the previous line indices on screen
## this is useful when mouse is outside Editor area,
## causing _estimate_min_max_line_num_onscreen()
## to return the entire script range.
var _previous_line_index_onscreen:Array[int] = [0,-1]



##1r# DOC find the line index range to be updated for the current viewport
func _get_onscreen_line_index_range_and_stretch() -> Array[int]:
	var editor_size:Vector2 = face_editor.size
	var ceiling_mid:Vector2 = Vector2(editor_size.x/2, 0)
	var floor_mid  :Vector2 = Vector2(editor_size.x/2, editor_size.y)
	var min_line_index:int = face_editor.get_line_column_at_pos(ceiling_mid).y
	var max_line_index:int = face_editor.get_line_column_at_pos(floor_mid).y
	# stretch the range to draw bg color whose parent comment is out of sight, and inactive otherwise
	var stretch:int = Settings.MAX_COMMENT_BG_COLOR_LINE_COUNT
	min_line_index = max(0, min_line_index - stretch)
	max_line_index = min(face_editor.get_line_count()-1, max_line_index + stretch / 2)
	return [min_line_index, max_line_index]


##1r# get index range of color encode in given string
## return: [start_index(inclusive), end_index(inclusive)]
## return [] if encode is not found
func _get_color_encode_range(string:String) -> Array[int]:
	# check: does the string contain a valid color encode?
	var res = head_space_encode_regex.search(string); var encode:String
	if res: encode = res.get_string().strip_edges()
	else: return [] # no valid encode returns []
	#2m# find the index of the first non-empty character
	var start:= -1
	for i in string.length(): if !["\t", " "].has(string[i]): start = i; break
	# check: is the encode at the start of the string
	if string.substr(start, encode.length()) == encode: return [start, start+encode.length()-1]
	else: return []


## DOC configure all buttons every time they are to appear
## 1. fix the size, fill in the missing buttons
## 2. configure buttons, connect them to face_editor
func _display_comment_buttons():
	_hide_comment_buttons()
	#12m#  fix size, fill in the missing comment buttons
	var size_diff = _color_comment_line_numbers.size() - _shared_comment_button_pool.size()
	if size_diff > 0:
		for i in size_diff:
			var button:CommentButton = CommentButtonScene.instantiate()
			_shared_comment_button_pool.append(button)
			face_editor.add_child(button)
			button.z_index = 10
			button.visible = false
			button.plus_button_down.connect(_grow_comment_bg_color_area)
			button.minus_button_down.connect(_shrink_comment_bg_color_area)
			button.fold_unfold_down.connect(_fold_custom_region)
			button.color_button_down.connect(_rotate_color)
	
	# configure the buttons to be displayed
	var temp_string:String
	for i in _color_comment_line_numbers.size():
		#1m# edge case: in last line, button is outside editor's rect, error, out of rect
		# since last-line comment has no code to serve, just ignore the edge case
		if _color_comment_line_numbers[i] == face_editor.get_line_count()-1: continue
		var siz = EDITOR_LINE_HEIGHT
		#11i# calculate encode's line index
		var line_index = _color_comment_line_numbers[i]
		# get the line string
		temp_string = face_editor.get_line(line_index)
		# get encode's range in string
		var minmax = _get_color_encode_range(temp_string)
		if minmax == []: continue
		# get first letter's top left corner or position
		# then add (6-letter-width or 2-height-width), I choose height for convenience
		# it will leave fixed spaced even when the encode's length changes
		var top_left:Vector2 = \
		face_editor.get_rect_at_line_column(line_index, minmax[0]+1).position

		top_left += Vector2(siz * 2, 0)
		
		# abort cuz it's outside viewport
		if top_left.x < face_editor.get_total_gutter_width(): continue
		
		#8# configure
		# button size and pos
		_shared_comment_button_pool[i].position = top_left
		_shared_comment_button_pool[i].setup_minimum_size(siz)
		# button color
		var color_encode = temp_string.substr(minmax[0], minmax[1]-minmax[0]+1)
		var this_char = _extract_color_char_from_encode(color_encode)
		var next_char = _extract_next_color_char_from_encode(color_encode)
		_shared_comment_button_pool[i].setup_color(
			_get_color_from_char(this_char), _get_color_from_char(next_char))
		
		_shared_comment_button_pool[i].visible = true
		_shared_comment_button_pool[i].line_index = line_index
		#1# fix mouse wheel font change causing panel container's inaccurate size
		_shared_comment_button_pool[i].size = _shared_comment_button_pool[i].get_combined_minimum_size()



## DOC configure all buttons every time they are to hide
func _hide_comment_buttons():
	for b in _shared_comment_button_pool:
		b.visible = false



## DOC remove one line of bg color below the comment at line_index
func _shrink_comment_bg_color_area(line_index:int):
	# extract code
	var string = face_editor.get_line(line_index)
	var minmax = _get_color_encode_range(string)
	var encode = string.substr(minmax[0], minmax[1]-minmax[0]+1)
	var color_char = _extract_color_char_from_encode(encode)
	var prefix = "#" if encode[1] != "#" else "##"
	# shrink
	var height:int = encode.to_int() - 1; if height < 1: height = 1
	encode = prefix + str(height) + color_char + "#"
	#replace
	string = string.erase(minmax[0], minmax[1]-minmax[0]+1)
	string = string.insert(minmax[0], encode)
	face_editor.set_line(line_index, string)
	
	var extra = _how_many_extra_comment_lines(line_index)
	_update_comment_bg_colors(line_index, (line_index+1)+extra+(height+1))




## DOC grow one line of bg color below the comment at line_index
func _grow_comment_bg_color_area(line_index:int):
	# extract minmax, encode, and color_char
	var string = face_editor.get_line(line_index)
	var minmax = _get_color_encode_range(string)
	var encode = string.substr(minmax[0], minmax[1]-minmax[0]+1)
	var color_char = _extract_color_char_from_encode(encode)
	var prefix = "#" if encode[1] != "#" else "##"
	# grow
	encode = encode.to_int() + 1;
	encode = min(encode, Settings.MAX_COMMENT_BG_COLOR_LINE_COUNT)
	encode = prefix + str(encode) + color_char + "#"
	#replace
	string = string.erase(minmax[0], minmax[1]-minmax[0]+1)
	string = string.insert(minmax[0], encode)
	face_editor.set_line(line_index, string)
	_update_comment_bg_colors(line_index, line_index+1)


## DOC region tags for custom region fold/unfold [constant ReadingAid.CUSTOM_REGION_START_TAG]
const CUSTOM_REGION_START_TAG  = "customregiontagstart"
const CUSTOM_REGION_END_TAG    = "customregiontagend"
const DEFAULT_REGION_START_TAG = "region"
const DEFAULT_REGION_END_TAG   = "endregion"



## DOC fold / unfold the custom comment encode
## HACK this func is full of hack. custom fold is achieved by manipulating
## region tags with the unwanted side effect of undo-redo space polution
func _fold_custom_region(line_index:int):
	if face_editor.is_line_folded(line_index):
		face_editor.unfold_line(line_index)
		# after fold/unfold altering line positions, re-display buttons to correct position
		# HACK for some reason, _display_comment_buttons can't use new button positions,
		# but use old positions. But the new position does come through 0.00001s after.
		# To safely get the new position, a 0.1s delayed update is used.
		get_tree().create_timer(0.05).timeout.connect(_display_comment_buttons)
		return
	#4m# make sure the last line is empty, which is necessary for region tags.
	var maxi = face_editor.get_line_count()
	if face_editor.get_line(maxi-1).strip_edges() != "":
		face_editor.insert_line_at(maxi-1, "")
		face_editor.swap_lines(maxi-1, maxi)
	var string = face_editor.get_line(line_index)
	var minmax:Array[int] = _get_color_encode_range(string)
	var comment_line_count = 1 + _how_many_extra_comment_lines(line_index)
	var code_line_count:int = string.to_int()
	var color_line_count = comment_line_count + code_line_count
	# insert region tags (!! last line is guarenteed empty)
	face_editor.set_code_region_tags(CUSTOM_REGION_START_TAG, CUSTOM_REGION_END_TAG)
	face_editor.insert_line_at(line_index, "#"+CUSTOM_REGION_START_TAG)
	face_editor.insert_line_at(line_index+color_line_count, "#"+CUSTOM_REGION_END_TAG)
	face_editor.fold_line(line_index)
	# reset tags
	# WARNING upon deleting line in region, region doesn't shrink size
	# it'll just take an innocent line as extra to fill up the missing space
	# the first line won't eat innocent lines, because it's technically outside the region
	face_editor.set_code_region_tags(DEFAULT_REGION_START_TAG, DEFAULT_REGION_END_TAG)
	face_editor.set_caret_column(0, false);
	face_editor.set_caret_line(max(line_index-1,0), false)
	face_editor.remove_text(line_index+color_line_count, 0, line_index+color_line_count+1, 0)
	face_editor.remove_text(line_index, 0, line_index+1, 0)
	# after fold/unfold altering line positions, re-display buttons to correct position
	# HACK for some reason, _display_comment_buttons can't use new button positions,
	# but use old positions. But the new position does come through 0.00001s after.
	# To safely get the new position, a 0.1s delayed update is used.
	get_tree().create_timer(0.05).timeout.connect(_display_comment_buttons)


func _rotate_color(line_index:int):
	var string = face_editor.get_line(line_index)
	var minmax = _get_color_encode_range(string)
	var encode = string.substr(minmax[0], minmax[1]-minmax[0]+1)

	var new_color_char = _extract_next_color_char_from_encode(encode)

	#5m# manipulate the string
	var prefix = "##" if encode[1] == "#" else "#"
	var number = encode.to_int()
	var new_encode = prefix + str(number) + new_color_char + "#"

	string = string.erase(minmax[0], minmax[1]-minmax[0]+1).insert(minmax[0], new_encode)
	
	#4i# find the button (_color_comment_line_numbers and _buttons indices match)
	var button_index
	for i in _color_comment_line_numbers.size():
		if _color_comment_line_numbers[i] == line_index:
			button_index = i
	var new_new_color_char = _extract_next_color_char_from_encode(new_encode)
	var old_color:Color = _get_color_from_char(new_color_char)
	var new_color:Color = _get_color_from_char(new_new_color_char)
	_shared_comment_button_pool[button_index].setup_color(old_color, new_color)
		
	face_editor.set_line(line_index, string) # string that contains new color char
	_update_comment_bg_colors(line_index, line_index+1)

#FEATURE display current function at the top
#FEATURE bookmarks
#FEATURE search for func uses
#FEATURE search for variable uses

#TODO hotkey rotate var num todo
#TODO improve keyword (todo) extraction
#TODO setting to configure buttons
#TODO improve region and func animation

#BUG holding ctrl while resizing the window permanently leaves tags on.
#BUG switching NEW script auto bring up bot menu array
#BUG func and region buttons animation sometimes get stuck for no reason
