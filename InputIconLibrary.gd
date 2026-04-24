extends Node
class_name InputIconLibrary

static var atlas: Texture2D = preload("uid://cfgt6ir2sax6h")

const HFRAMES: int = 34
const VFRAMES: int = 24
const DEBUG_ICONS: bool = true


# PUBLIC

static func get_unpressed_icon(action_name: String) -> Texture2D:
	var event := _get_keyboard_binding(action_name)

	if event == null:
		if DEBUG_ICONS:
			print("[InputIconLibrary] ❌ No keyboard binding for:", action_name)
		return null

	if DEBUG_ICONS:
		print("\n[InputIconLibrary] =====")
		print("[InputIconLibrary] action:", action_name)
		print("[InputIconLibrary] event:", InputSettings.event_to_text(event))
		print("[InputIconLibrary] class:", event.get_class())

	# SPECIAL WIDE KEYS
	if event is InputEventKey:
		var key := (event as InputEventKey).physical_keycode

		match key:
			KEY_SPACE:
				if DEBUG_ICONS:
					print("[InputIconLibrary] Using WIDE SPACE")
				return _make_icon_from_cells(31, 6, 3, 1) # tweak width if needed

	var frame_index := _get_frame_for_event(event)

	if DEBUG_ICONS:
		print("[InputIconLibrary] frame index:", frame_index)

	if frame_index < 0:
		print("[InputIconLibrary] ❌ No frame mapped")
		return null

	return _make_icon_from_frame(frame_index)


static func get_pressed_icon(action_name: String) -> Texture2D:
	return get_unpressed_icon(action_name)


# BINDING

static func _get_keyboard_binding(action_name: String) -> InputEvent:
	var bindings: Array[InputEvent] = InputSettings.get_bindings(StringName(action_name))

	if DEBUG_ICONS:
		print("[InputIconLibrary] bindings for", action_name, ":")

	for event in bindings:
		if DEBUG_ICONS:
			print("  -", InputSettings.event_to_text(event), "/", event.get_class())

		if event is InputEventKey:
			return event

	return null


# ICON CREATION

static func _make_icon_from_frame(frame_index: int) -> Texture2D:
	var frame_w := float(atlas.get_width()) / float(HFRAMES)
	var frame_h := float(atlas.get_height()) / float(VFRAMES)

	var col := frame_index % HFRAMES
	var row := int(frame_index / HFRAMES)

	if DEBUG_ICONS:
		print("[InputIconLibrary] col:", col, "row:", row)

	var tex := AtlasTexture.new()
	tex.atlas = atlas
	tex.region = Rect2(col * frame_w, row * frame_h, frame_w, frame_h)
	tex.filter_clip = true
	return tex


static func _make_icon_from_cells(col: int, row: int, w: int, h: int) -> Texture2D:
	var frame_w := float(atlas.get_width()) / float(HFRAMES)
	var frame_h := float(atlas.get_height()) / float(VFRAMES)

	var region := Rect2(
		col * frame_w,
		row * frame_h,
		frame_w * w,
		frame_h * h
	)

	if DEBUG_ICONS:
		print("[InputIconLibrary] WIDE region:", region)

	var tex := AtlasTexture.new()
	tex.atlas = atlas
	tex.region = region
	tex.filter_clip = true
	return tex


# FRAME LOOKUP

static func _frame(col: int, row: int) -> int:
	return row * HFRAMES + col


static func _get_frame_for_event(event: InputEvent) -> int:
	if event is InputEventMouseButton:
		return _get_mouse_frame((event as InputEventMouseButton).button_index)

	if event is InputEventJoypadButton:
		return _get_joy_button_frame((event as InputEventJoypadButton).button_index)

	if event is InputEventJoypadMotion:
		return _get_joy_motion_frame(event as InputEventJoypadMotion)

	if event is InputEventKey:
		return _get_key_frame((event as InputEventKey).physical_keycode)

	return -1


# MAPPINGS

static func _get_mouse_frame(button_index: MouseButton) -> int:
	match button_index:
		MOUSE_BUTTON_LEFT:
			return _frame(18, 17)
		MOUSE_BUTTON_RIGHT:
			return _frame(19, 17)
		MOUSE_BUTTON_MIDDLE:
			return _frame(20, 17)
		_:
			return -1


static func _get_joy_button_frame(button_index: int) -> int:
	match button_index:
		0:
			return _frame(0, 20)
		1:
			return _frame(1, 20)
		2:
			return _frame(2, 20)
		3:
			return _frame(3, 20)
		_:
			return -1


static func _get_joy_motion_frame(event: InputEventJoypadMotion) -> int:
	match event.axis:
		0:
			return _frame(3, 21)
		1:
			return _frame(1, 21)
		_:
			return -1


static func _get_key_frame(keycode: Key) -> int:
	match keycode:
		KEY_Q: return _frame(17, 2)
		KEY_W: return _frame(18, 2)
		KEY_E: return _frame(19, 2)
		KEY_R: return _frame(20, 2)

		KEY_A: return _frame(18, 3)
		KEY_S: return _frame(19, 3)
		KEY_D: return _frame(20, 3)
		KEY_F: return _frame(21, 3)

		KEY_SHIFT: return _frame(14, 4)
		KEY_CTRL: return _frame(14, 5)
		KEY_ALT: return _frame(15, 5)

		KEY_SPACE: return _frame(20, 5)

		KEY_UP: return _frame(31, 4)
		KEY_LEFT: return _frame(30, 5)
		KEY_DOWN: return _frame(31, 5)
		KEY_RIGHT: return _frame(32, 5)

		_:
			return -1
