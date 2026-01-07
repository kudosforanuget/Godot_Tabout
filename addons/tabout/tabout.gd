@tool
extends EditorPlugin

# This dictionary maps closing characters to their opening counterparts
const PAIRS = {
	")": "(",
	"]": "[",
	"}": "{",
	">": "<",
	"\"": "\"",
	"'": "'"
}

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_TAB:
		var focus_owner = get_viewport().gui_get_focus_owner()
		
		# Check if the user is currently typing in a CodeEdit (Script Editor)
		if focus_owner is CodeEdit:
			
			# Shift + Tab: Jump Left (Back into the pair)
			if event.shift_pressed:
				if _should_tab_in(focus_owner):
					focus_owner.set_caret_column(focus_owner.get_caret_column() - 1)
					get_viewport().set_input_as_handled()
			
			# Regular Tab: Jump Right (Out of the pair)
			else:
				if _should_tab_out(focus_owner):
					focus_owner.set_caret_column(focus_owner.get_caret_column() + 1)
					get_viewport().set_input_as_handled()

func _should_tab_out(code_edit: CodeEdit) -> bool:
	if code_edit.has_selection():
		return false
		
	var line_text = code_edit.get_line(code_edit.get_caret_line())
	var col = code_edit.get_caret_column()
	
	# Safety: Ensure there's a character in front of the cursor
	if col >= line_text.length():
		return false
		
	var char_at_cursor = line_text[col]
	
	if not PAIRS.has(char_at_cursor):
		return false
		
	var opener = PAIRS[char_at_cursor]
	var text_to_left = line_text.left(col)
	
	# Case 1: Quotes
	if char_at_cursor == "\"" or char_at_cursor == "'":
		# Jump out if there is an odd number of quotes to the left (we are inside)
		return text_to_left.count(char_at_cursor) % 2 == 1
		
	# Case 2: Brackets/Parens
	var opener_count = text_to_left.count(opener)
	var closer_count = text_to_left.count(char_at_cursor)
	
	# Jump out if there are more openers than closers on this line
	return opener_count > closer_count

func _should_tab_in(code_edit: CodeEdit) -> bool:
	if code_edit.has_selection():
		return false
		
	var line_text = code_edit.get_line(code_edit.get_caret_line())
	var col = code_edit.get_caret_column()
	
	# Safety: Ensure there's a character behind the cursor
	if col <= 0:
		return false
		
	var char_to_left = line_text[col - 1]
	
	if not PAIRS.has(char_to_left):
		return false
		
	var opener = PAIRS[char_to_left]
	var text_before_left = line_text.left(col - 1)
	
	# Case 1: Quotes
	if char_to_left == "\"" or char_to_left == "'":
		# Jump in if the quote to our left was a closing quote (odd count before it)
		return text_before_left.count(char_to_left) % 2 == 1
		
	# Case 2: Brackets/Parens
	var opener_count = text_before_left.count(opener)
	var closer_count = text_before_left.count(char_to_left)
	
	# Jump in if that closer was part of an active pair on this line
	return opener_count > closer_count
