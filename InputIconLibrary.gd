extends Node
class_name InputIconLibrary

# Texture atlas that contains all input icons
static var atlas: Texture2D = preload("uid://cfgt6ir2sax6h")

# Grid layout of the atlas
const HFRAMES: int = 34
const VFRAMES: int = 24


# Returns the icon for an action (unpressed state)
static func get_unpressed_icon(action_name: String) -> Texture2D:
	var event := get_first_binding_for_action(action_name)

	if event == null:
		return null

	# Special handling for wide keys (spacebar)
	if event is InputEventKey:
		var key := (event as InputEventKey).physical_keycode

		if key == KEY_SPACE:
			return make_icon_from_cells(31, 6, 3, 1)

	# Default: look up frame normally
	var frame_index := get_frame_for_event(event)

	if frame_index < 0:
		return null

	return make_icon_from_frame(frame_index)


# Pressed icon currently reuses the same texture
static func get_pressed_icon(action_name: String) -> Texture2D:
	return get_unpressed_icon(action_name)


# Gets the first binding for an action (respects player rebinds)
static func get_first_binding_for_action(action_name: String) -> InputEvent:
	var action := prompt_to_action(action_name)
	var bindings: Array[InputEvent] = InputSettings.get_bindings(action)

	# Fallback to default InputMap if custom bindings are empty
	if bindings.is_empty():
		bindings = InputMap.action_get_events(action)

	if bindings.is_empty():
		return null

	return bindings[0]


# Maps prompt names to actual input actions
static func prompt_to_action(prompt_name: String) -> StringName:
	match prompt_name.to_lower():
		"interact": return &"action"
		"action": return &"action"
		"jump": return &"jump"
		"attack": return &"attack"
		"dash": return &"dash"
		"pause": return &"pause"
		"cast": return &"Cast"
		"up": return &"up"
		"down": return &"down"
		"left": return &"left"
		"right": return &"right"
		_: return StringName(prompt_name)


# Converts a frame index into an icon
static func make_icon_from_frame(frame_index: int) -> Texture2D:
	var col := frame_index % HFRAMES
	var row := int(frame_index / HFRAMES)
	return make_icon_from_cells(col, row, 1, 1)


# Creates an icon from a region of the atlas
static func make_icon_from_cells(col: int, row: int, w: int, h: int) -> Texture2D:
	var frame_w := float(atlas.get_width()) / float(HFRAMES)
	var frame_h := float(atlas.get_height()) / float(VFRAMES)

	var tex := AtlasTexture.new()
	tex.atlas = atlas
	tex.region = Rect2(
		col * frame_w,
		row * frame_h,
		frame_w * w,
		frame_h * h
	)
	tex.filter_clip = true

	return tex


# Converts column/row into a frame index
static func frame(col: int, row: int) -> int:
	return row * HFRAMES + col


# Determines which mapping to use based on input type
static func get_frame_for_event(event: InputEvent) -> int:
	if event is InputEventMouseButton:
		return get_mouse_frame((event as InputEventMouseButton).button_index)

	if event is InputEventJoypadButton:
		return get_joy_button_frame((event as InputEventJoypadButton).button_index)

	if event is InputEventJoypadMotion:
		return get_joy_motion_frame(event as InputEventJoypadMotion)

	if event is InputEventKey:
		return get_key_frame((event as InputEventKey).physical_keycode)

	return -1


# Mouse button mapping
static func get_mouse_frame(button_index: MouseButton) -> int:
	match button_index:
		MOUSE_BUTTON_LEFT: return frame(18, 17)
		MOUSE_BUTTON_RIGHT: return frame(19, 17)
		MOUSE_BUTTON_MIDDLE: return frame(20, 17)
		MOUSE_BUTTON_WHEEL_UP: return frame(21, 17)
		MOUSE_BUTTON_WHEEL_DOWN: return frame(22, 17)
		MOUSE_BUTTON_XBUTTON1: return frame(23, 17)
		MOUSE_BUTTON_XBUTTON2: return frame(24, 17)
		_: return -1


# Controller button mapping
static func get_joy_button_frame(button_index: int) -> int:
	match button_index:
		0: return frame(0, 20)
		1: return frame(1, 20)
		2: return frame(2, 20)
		3: return frame(3, 20)
		4: return frame(8, 20)
		5: return frame(9, 20)
		6: return frame(8, 21)
		7: return frame(9, 21)
		10: return frame(13, 19)
		11: return frame(14, 19)
		12: return frame(15, 19)
		13: return frame(16, 19)
		14: return frame(17, 19)
		_: return -1


# Controller stick mapping
static func get_joy_motion_frame(event: InputEventJoypadMotion) -> int:
	match event.axis:
		0:
			return frame(3, 21) if event.axis_value < 0.0 else frame(4, 21)
		1:
			return frame(1, 21) if event.axis_value < 0.0 else frame(2, 21)
		2:
			return frame(10, 20)
		3:
			return frame(11, 20)
		_: return -1


# Keyboard mapping (matches your atlas layout)
static func get_key_frame(keycode: Key) -> int:
	match keycode:
		KEY_ESCAPE: return frame(30, 0)

		KEY_1: return frame(16, 1)
		KEY_2: return frame(17, 1)
		KEY_3: return frame(18, 1)
		KEY_4: return frame(19, 1)
		KEY_5: return frame(20, 1)
		KEY_6: return frame(21, 1)
		KEY_7: return frame(22, 1)
		KEY_8: return frame(23, 1)
		KEY_9: return frame(24, 1)
		KEY_0: return frame(25, 1)

		KEY_Q: return frame(17, 2)
		KEY_W: return frame(18, 2)
		KEY_E: return frame(19, 2)
		KEY_R: return frame(20, 2)
		KEY_T: return frame(21, 2)
		KEY_Y: return frame(22, 2)
		KEY_U: return frame(23, 2)
		KEY_I: return frame(24, 2)
		KEY_O: return frame(25, 2)
		KEY_P: return frame(26, 2)

		KEY_A: return frame(18, 3)
		KEY_S: return frame(19, 3)
		KEY_D: return frame(20, 3)
		KEY_F: return frame(21, 3)
		KEY_G: return frame(22, 3)
		KEY_H: return frame(23, 3)
		KEY_J: return frame(24, 3)
		KEY_K: return frame(25, 3)
		KEY_L: return frame(26, 3)

		KEY_Z: return frame(19, 4)
		KEY_X: return frame(20, 4)
		KEY_C: return frame(21, 4)
		KEY_V: return frame(22, 4)
		KEY_B: return frame(23, 4)
		KEY_N: return frame(24, 4)
		KEY_M: return frame(25, 4)

		KEY_TAB: return frame(14, 2)
		KEY_BACKSPACE: return frame(31, 1)
		KEY_ENTER: return frame(29, 3)

		KEY_SHIFT: return frame(14, 4)
		KEY_CTRL: return frame(14, 5)
		KEY_ALT: return frame(16, 5)

		KEY_SPACE: return -1

		KEY_UP: return frame(30, 4)
		KEY_LEFT: return frame(33, 4)
		KEY_DOWN: return frame(32, 4)
		KEY_RIGHT: return frame(31, 4)

		_: return -1
