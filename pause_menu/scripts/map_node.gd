@tool
class_name MapNode
extends Control

# Scene this node represents.
@export_file("*.tscn") var linked_scene: String = ""

# Display info.
@export var display_name: String = ""
@export var region_name: String = "wraith_woods"

# Visibility / labels.
@export var hide_until_discovered: bool = false
@export var show_label_in_game: bool = false

# Manual openings.
@export_group("Manual Openings")
@export var openings_top: Array[float] = []
@export var openings_right: Array[float] = []
@export var openings_bottom: Array[float] = []
@export var openings_left: Array[float] = []

# Colors.
@export_group("Colors")
@export var default_fill_color: Color = Color("000000")
@export var default_border_color: Color = Color("ffffff")
@export var current_fill_color: Color = Color("5a1f72")
@export var current_border_color: Color = Color("ff7cff")

# Internal refs.
var label: Label
var transition_blocks: Control

var room_fill_color: Color
var room_border_color: Color
var is_current_room: bool = false



#READY

func _ready() -> void:
	ensure_minimum_nodes()

	if Engine.is_editor_hint():
		if label:
			label.visible = false
		create_transition_blocks()
		queue_redraw()
		return

	refresh_node()



#SETUP

func ensure_minimum_nodes() -> void:

	if not has_node("Label"):
		var l := Label.new()
		l.name = "Label"
		add_child(l)

	if not has_node("TransitionBlocks"):
		var t := Control.new()
		t.name = "TransitionBlocks"
		add_child(t)

	label = get_node("Label") as Label
	transition_blocks = get_node("TransitionBlocks") as Control



#PATH HELPERS

func get_scene_path() -> String:

	if linked_scene == "":
		return ""

	if linked_scene.begins_with("uid://"):
		var uid_id: int = ResourceUID.text_to_id(linked_scene)
		if uid_id != -1:
			var resolved_path: String = ResourceUID.get_id_path(uid_id)
			if resolved_path != "":
				return resolved_path

	return linked_scene



#REFRESH

func refresh_node() -> void:

	var current_scene := get_tree().current_scene.scene_file_path
	var scene_path: String = get_scene_path()
	is_current_room = (current_scene == scene_path)

	room_fill_color = default_fill_color
	room_border_color = default_border_color

	if hide_until_discovered:
		var discovered := SaveManager.is_area_discovered(scene_path)
		visible = discovered
	else:
		visible = true

	if label:
		label.visible = false

	create_transition_blocks()
	queue_redraw()



#DRAW

func _draw() -> void:

	var rect := Rect2(Vector2.ZERO, size)

	var fill := room_fill_color
	var border := room_border_color

	if is_current_room:
		fill = current_fill_color
		border = current_border_color

	draw_rect(rect, fill, true)
	draw_rect(rect, border, false, 1.0)



#OPENINGS DRAW

func create_transition_blocks() -> void:

	if not transition_blocks:
		return

	for c in transition_blocks.get_children():
		c.queue_free()

	var side_thickness := 1.0
	var opening_length := 3.0

	for t in openings_left:
		var b := add_block()
		b.size = Vector2(side_thickness, opening_length)
		b.position = Vector2(0, t - (opening_length * 0.5))

	for t in openings_right:
		var b := add_block()
		b.size = Vector2(side_thickness, opening_length)
		b.position = Vector2(size.x - side_thickness, t - (opening_length * 0.5))

	for t in openings_top:
		var b := add_block()
		b.size = Vector2(opening_length, side_thickness)
		b.position = Vector2(t - (opening_length * 0.5), 0)

	for t in openings_bottom:
		var b := add_block()
		b.size = Vector2(opening_length, side_thickness)
		b.position = Vector2(t - (opening_length * 0.5), size.y - side_thickness)



func add_block() -> ColorRect:
	var b := ColorRect.new()
	b.color = room_fill_color
	transition_blocks.add_child(b)
	return b
