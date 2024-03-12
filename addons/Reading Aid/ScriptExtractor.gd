extends Object
class_name ScriptExtractor


## NOTE extract enums from an editor, organize info and return
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
## extract todos and return everything in a giant block
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
