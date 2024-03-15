extends Object
class_name ScriptExtractor


##1# DOC extract enums from an editor, organize info and return
##           Line : { text, line_number}
## one_enum_block : Array[Line]
##          enums : Array[one_enum_block] or Array[Array[Line]]
static func extract_enums(editor:CodeEdit) -> Array[Array]:
	var index:= 0
	var line_count: = editor.get_line_count()
	var line:= ""
	var start:= 0
	var end  := -1
	var enums:Array[Array] = []
	var one_enum_block:Array[Line] = []
	
	var failsafe = -1
	while index < line_count:
		if failsafe == index: printt("failsafe triggered. loop index:", index); break
		failsafe = index
	
		line = editor.get_line(index)
		if line.substr(0,5) == "enum ": # locate start
			start = index
			while index < line_count:   # search end
				line = editor.get_line(index)
				if line.contains("}"):  # locate end
					end = index
					break
				else: index += 1
			if end >= start: # if successfully locate enum
				one_enum_block = []  # extract lines from start to end
				for i in range(start, end+1):
					one_enum_block.append(Line.new(editor.get_line(i), i))
				#enums.append("\n".join(extracted_enum_lines))
				enums.append(one_enum_block)
				index = end+1
			else:
				# it seems there are no more "}" to match "enum", can't pair no more.
				# end search
				break
		else:
			index += 1
			
	return enums


##1#
static func extract_vars(editor:CodeEdit) -> Array[Array]:
	var vars:Array[Array] = []
	var line_count = editor.get_line_count()
	var index = 0
	var temp_string = ""
	var prev_string = ""
	var previous_var_index = -1
	var comment_starting_index = -1
	while index < line_count:
		temp_string = editor.get_line(index)
		if _is_var_or_constant_or_annotation(temp_string): # found new "var " line
			#24# try to merge to previous var block
			if index-1 >= 0: 
				prev_string = editor.get_line(index-1)
				# prev line is "var "
				if _is_var_or_constant_or_annotation(prev_string):
					vars[-1].append(Line.new(temp_string, index))
				# prev line is empty, but then "var "
				elif prev_string.strip_edges() == "" and index-2 >= 0 \
				and _is_var_or_constant_or_annotation(editor.get_line(index-2)):
					vars[-1].append(Line.new("", index-1))
					vars[-1].append(Line.new(temp_string, index))
				# prev line has comments?
				else:
					comment_starting_index = index
					for i in range(index-1, previous_var_index, -1):
						if i < 0: break
						if editor.is_in_comment(i) >= 0: # has comment
							comment_starting_index = i
						else:
							break
					var code_block:Array[Line] = []
					var end_index = _get_end_index(editor, index) # to include get&set
					for i in range(comment_starting_index, end_index+1):
						code_block.append(Line.new(editor.get_line(i), i))
					previous_var_index = index
					vars.append(code_block)
		index += 1
	return vars


static func _is_var_or_constant_or_annotation(string:String) -> bool:
	if string.length() == 0: return false
	if string[0] == "v" and string.substr(0,4) == "var ": return true
	if string[0] == "c" and string.substr(0,6) == "const ": return true
	if string[0] == "@": return true
	return false

static func _is_constant(string:String) -> bool:
	if string.length() == 0: return false
	if string[0] == "c" and string.substr(0,6) == "const ": return true
	return false

static func _get_end_index(editor:CodeEdit, start:int) -> int:
	var end = start
	var index = start+1
	while index < editor.get_line_count():
		var line:String = editor.get_line(index)
		var is_comment = editor.is_in_comment(index) != -1
		var is_indented = line.length() > 0 and line[0] == "\t" # not empty and has indentation
		var is_code = line.strip_edges() != "" and !is_comment # not empty space and not comment
		if is_code:
			if is_indented: end = index
			else          : break
		index += 1
	return end

#FIXME doesn't include comments above the tagged lines
##1# extract todos and return everything in a giant block
static func extract_todos(editor:CodeEdit) -> Array[Array]:
	var one_block:Array[Line] = []
	var index:= 0
	var string:String
	const tags:Array[String] = ["TODO", "BUG", "TASK", "TBD", "FIXME", "FEATURE"]
	var line_count = editor.get_line_count()
	while index < line_count:
		string = editor.get_line(index)
		if editor.is_in_comment(index)>=0 and _contains_tag(string, tags):
			one_block.append(Line.new(string, index))
			for i in range(index+1, line_count):
				string = editor.get_line(i)
				if editor.is_in_comment(i)>=0 and _contains_tag(string, tags):
					one_block.append(Line.new(string, i))
				else: break
			index = one_block[-1].line_number + 1
		else:
			index += 1
	
	return [[Line.new("#TODO_VIWERE HACK THIS FEATURE IS INCOMPLETE", 0)] as Array[Line], one_block]


## examine whether the string contains one of the given tags
static func _contains_tag(string:String, tags:Array[String]) -> bool:
	for tag in tags:
		if string.contains(tag): return true
	return false





#TODO needs init?

##1r#
static var head_space_encode_regex:RegEx:
	get:
		if head_space_encode_regex == null:
			head_space_encode_regex = RegEx.new()
			var color_palette_string = "".join(Settings.PALETTE.keys())
			head_space_encode_regex.compile("^\\s*#{1,2}[0-9]+[" + color_palette_string + "]{0,1}#")
		return head_space_encode_regex


##1r#
static func assert_valid_encode(encode:String):
	var res = head_space_encode_regex.search(encode)
	assert(res!=null and res.get_string().strip_edges() == encode,
	"func _assert_valid_encode: bad comment encoding: \"" + encode + "\"")


##1r# DOC Sometimes, the returned char is a valid key in palette, sometimes, it's not
## WARNING When it's not a valid key, the invald chars should be a number.
static func color_char_from_encode(encode:String) -> String:
	assert_valid_encode(encode)
	var char = encode[-2]
	if "0123456789".contains(char): return ""
	return char


##1r# DOC in palette, find the char next to the one provided in the encode
static func next_color_char_from_encode(encode:String) -> String:
	var color_char = color_char_from_encode(encode)
	var keys = Settings.PALETTE.keys()
	# in case of not found, find would be -1, next would be 0, perfect
	var next_index = keys.find(color_char) + 1;
	#2m# if next_index is out of bound, return an invalid color char
	if next_index == keys.size(): return ""
	return keys[next_index]


##1r# get color from palette corresponding to the given char
## WARNING the parameter char can be an invalid key in palette.
## Use dictionary's default parameter
static func color_from_char(color_char:String) -> Color:
	return Settings.PALETTE.get(color_char, Settings.PLACEHOLDER_COLOR)


##1r# get index range of color encode in given string
## return: [start_index(inclusive), end_index(inclusive)]
## return [] if encode is not found
static func get_color_encode_range(string:String) -> Array[int]:
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


##1r# Count extra comments. Emphasis is on extra, meaning starting from line 2 of the comment section
static func extra_comment_lines(editor:CodeEdit, line_index:int):
	var index = line_index+1
	var count = 0
	while index < editor.get_line_count():
		if editor.is_in_comment(index) >= 0: count += 1
		else: break
		index += 1
	return count
