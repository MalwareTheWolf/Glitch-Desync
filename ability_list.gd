extends Control

@onready var root_box: VBoxContainer = get_node_or_null("VBoxContainer")
@onready var header_row: HBoxContainer = get_node_or_null("VBoxContainer/HeaderRow")
@onready var title_label: Label = get_node_or_null("VBoxContainer/HeaderRow/Title")

@onready var content_row: HBoxContainer = get_node_or_null("VBoxContainer/ContentRow")
@onready var left_column: VBoxContainer = get_node_or_null("VBoxContainer/ContentRow/LeftColumn")
@onready var scroll_container: ScrollContainer = get_node_or_null("VBoxContainer/ContentRow/LeftColumn/ScrollContainer")
@onready var ability_list: VBoxContainer = get_node_or_null("VBoxContainer/ContentRow/LeftColumn/ScrollContainer/AbilityList")

@onready var right_column: VBoxContainer = get_node_or_null("VBoxContainer/ContentRow/RightColumn")
@onready var preview_margin: MarginContainer = get_node_or_null("VBoxContainer/ContentRow/RightColumn/MarginContainer")
@onready var preview_vbox: VBoxContainer = get_node_or_null("VBoxContainer/ContentRow/RightColumn/MarginContainer/PreviewVBox")
@onready var preview_title: Label = get_node_or_null("VBoxContainer/ContentRow/RightColumn/MarginContainer/PreviewVBox/PreviewTitle")
@onready var preview_description: Label = get_node_or_null("VBoxContainer/ContentRow/RightColumn/MarginContainer/PreviewVBox/PreviewDescription")

# IMPORTANT: this now points to PreviewRoot inside the SubViewport
@onready var preview_scene_holder: Node = get_node_or_null("VBoxContainer/ContentRow/RightColumn/MarginContainer/PreviewVBox/PreviewSceneHolder/SubViewportContainer/SubViewport/PreviewRoot")

@onready var preview_video: VideoStreamPlayer = get_node_or_null("VBoxContainer/ContentRow/RightColumn/MarginContainer/PreviewVBox/PreviewVideo")


const TITLE_FONT_SIZE: int = 11
const ITEM_FONT_SIZE: int = 9
const DESC_FONT_SIZE: int = 8

const HEADER_HEIGHT: float = 22.0
const LEFT_COLUMN_WIDTH: float = 130.0
const PREVIEW_MIN_HEIGHT: float = 120.0
const BUTTON_H: float = 22.0

var current_preview_instance: Node = null

var ability_defs: Array[Dictionary] = [
	{
		"id": "run",
		"title": "Run",
		"description": "Double tap a direction to start running.",
		"player_var": "run",
		"video": null,
		"scene": null
	},
	{
		"id": "dash",
		"title": "Dash",
		"description": "Burst forward quickly and avoid danger.",
		"player_var": "dash",
		"video": null,
		"scene": preload("res://UI/AbilityPreviews/Preview_Dash.tscn")
	},
	{
		"id": "double_jump",
		"title": "Double Jump",
		"description": "Jump again while airborne.",
		"player_var": "double_jump",
		"video": null,
		"scene": null
	},
	{
		"id": "ground_slam",
		"title": "Ground Slam",
		"description": "Strike downward with force from the air.",
		"player_var": "ground_slam",
		"video": null,
		"scene": null
	},
	{
		"id": "morph",
		"title": "Morph",
		"description": "Shift into your alternate movement form.",
		"player_var": "morph",
		"video": null,
		"scene": null
	},
	{
		"id": "lightning",
		"title": "Lightning",
		"description": "Cast a lightning-based attack.",
		"player_var": "lightning",
		"video": null,
		"scene": null
	},
	{
		"id": "Chain_lightning",
		"title": "Chain Lightning",
		"description": "Lightning that jumps between targets.",
		"player_var": "Chain_lightning",
		"video": null,
		"scene": null
	},
	{
		"id": "dark_blast",
		"title": "Dark Blast",
		"description": "Release a dark energy attack.",
		"player_var": "dark_blast",
		"video": null,
		"scene": null
	},
	{
		"id": "heavy_attack",
		"title": "Heavy Attack",
		"description": "A slower, stronger attack.",
		"player_var": "heavy_attack",
		"video": null,
		"scene": null
	},
	{
		"id": "power_up",
		"title": "Power Up",
		"description": "Temporarily enhance your combat output.",
		"player_var": "power_up",
		"video": null,
		"scene": null
	}
]


func _ready() -> void:
	if root_box == null or header_row == null or title_label == null or content_row == null or left_column == null or scroll_container == null or ability_list == null or right_column == null or preview_vbox == null:
		push_error("Ability page is missing one or more required nodes.")
		return

	_configure_layout()
	_configure_preview_defaults()

	call_deferred("refresh_ability_list")


func _configure_layout() -> void:
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	size_flags_vertical = Control.SIZE_EXPAND_FILL

	root_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root_box.add_theme_constant_override("separation", 6)

	header_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header_row.custom_minimum_size = Vector2(0.0, HEADER_HEIGHT)

	title_label.text = "Abilities"
	title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_label.add_theme_font_size_override("font_size", TITLE_FONT_SIZE)

	content_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content_row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content_row.add_theme_constant_override("separation", 12)

	left_column.size_flags_horizontal = Control.SIZE_FILL
	left_column.size_flags_vertical = Control.SIZE_EXPAND_FILL
	left_column.custom_minimum_size = Vector2(LEFT_COLUMN_WIDTH, 0.0)

	scroll_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll_container.custom_minimum_size = Vector2(LEFT_COLUMN_WIDTH, 0.0)

	ability_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ability_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	ability_list.custom_minimum_size = Vector2(LEFT_COLUMN_WIDTH - 6.0, 0.0)
	ability_list.add_theme_constant_override("separation", 4)

	right_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right_column.size_flags_vertical = Control.SIZE_EXPAND_FILL

	if preview_margin:
		preview_margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		preview_margin.size_flags_vertical = Control.SIZE_EXPAND_FILL

	preview_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	preview_vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	preview_vbox.add_theme_constant_override("separation", 12)

	if preview_title:
		preview_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		preview_title.size_flags_vertical = Control.SIZE_FILL
		preview_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		preview_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		preview_title.add_theme_font_size_override("font_size", TITLE_FONT_SIZE)
		preview_title.custom_minimum_size = Vector2(0.0, 22.0)

	if preview_description:
		preview_description.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		preview_description.size_flags_vertical = Control.SIZE_FILL
		preview_description.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		preview_description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		preview_description.add_theme_font_size_override("font_size", DESC_FONT_SIZE)
		preview_description.custom_minimum_size = Vector2(0.0, 30.0)

	# PreviewSceneHolder still exists as a Control in the scene,
	# but we are instancing the preview into PreviewRoot inside the SubViewport.
	if preview_video:
		preview_video.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		preview_video.size_flags_vertical = Control.SIZE_EXPAND_FILL
		preview_video.custom_minimum_size = Vector2(0.0, PREVIEW_MIN_HEIGHT)


func _configure_preview_defaults() -> void:
	if preview_title:
		preview_title.text = "No Ability Selected"

	if preview_description:
		preview_description.text = "Choose an unlocked ability from the list."

	if preview_video:
		preview_video.visible = false


func refresh_ability_list() -> void:
	if ability_list == null:
		return

	for child in ability_list.get_children():
		child.queue_free()

	var player: Player = get_tree().get_first_node_in_group("Player")
	if player == null:
		_clear_preview()
		return

	var unlocked_defs: Array[Dictionary] = []

	for def in ability_defs:
		var var_name: String = def.get("player_var", "")
		if var_name != "" and player.get(var_name):
			unlocked_defs.append(def)

	if unlocked_defs.is_empty():
		var none_label := Label.new()
		none_label.text = "No abilities unlocked yet."
		none_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		none_label.add_theme_font_size_override("font_size", ITEM_FONT_SIZE)
		ability_list.add_child(none_label)
		_clear_preview()
		return

	for def in unlocked_defs:
		ability_list.add_child(_build_ability_row(def))

	_show_preview(unlocked_defs[0])


func _build_ability_row(def: Dictionary) -> Control:
	var outer := VBoxContainer.new()
	outer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	outer.add_theme_constant_override("separation", 2)

	var button := Button.new()
	button.text = String(def.get("title", "Unknown"))
	button.custom_minimum_size = Vector2(LEFT_COLUMN_WIDTH - 10.0, BUTTON_H)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.focus_mode = Control.FOCUS_ALL
	button.clip_text = true
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.add_theme_constant_override("content_margin_left", 6)
	button.add_theme_font_size_override("font_size", ITEM_FONT_SIZE)
	button.pressed.connect(_on_ability_pressed.bind(def))
	outer.add_child(button)

	var divider := HSeparator.new()
	outer.add_child(divider)

	return outer


func _on_ability_pressed(def: Dictionary) -> void:
	_show_preview(def)


func _show_preview(def: Dictionary) -> void:
	if preview_title:
		preview_title.text = String(def.get("title", "Unknown"))

	if preview_description:
		preview_description.text = String(def.get("description", ""))

	if current_preview_instance and is_instance_valid(current_preview_instance):
		current_preview_instance.queue_free()
		current_preview_instance = null

	if preview_scene_holder:
		for child in preview_scene_holder.get_children():
			child.queue_free()

	if preview_video:
		preview_video.stop()
		preview_video.visible = false
		preview_video.stream = null

	var scene_res: PackedScene = def.get("scene", null)
	var video_res: VideoStream = def.get("video", null)

	if scene_res != null and preview_scene_holder != null:
		current_preview_instance = scene_res.instantiate()
		preview_scene_holder.add_child(current_preview_instance)

	elif video_res != null and preview_video != null:
		preview_video.stream = video_res
		preview_video.visible = true
		preview_video.play()


func _clear_preview() -> void:
	if preview_title:
		preview_title.text = "No Ability Selected"

	if preview_description:
		preview_description.text = "Choose an unlocked ability from the list."

	if current_preview_instance and is_instance_valid(current_preview_instance):
		current_preview_instance.queue_free()
		current_preview_instance = null

	if preview_scene_holder:
		for child in preview_scene_holder.get_children():
			child.queue_free()

	if preview_video:
		preview_video.stop()
		preview_video.visible = false
		preview_video.stream = null
