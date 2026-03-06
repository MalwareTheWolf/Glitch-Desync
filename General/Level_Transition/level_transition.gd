@icon("res://General/Icon/level_transition.svg")
@tool

class_name LevelTransition
extends Node2D
# Trigger zone used to transition between levels.
# When the player enters, SceneManager loads the next scene.



#        ENUMS

enum SIDE { LEFT, RIGHT, TOP, BOTTOM }
# Determines which direction the transition faces.



#        EXPORT SETTINGS
@export_range(2, 12, 1, "or_greater")
var size: int = 2:
	set(value):
		size = value
		apply_area_settings()
# Controls the length of the trigger area.


@export var location: SIDE = SIDE.LEFT:
	set(value):
		location = value
		apply_area_settings()
# Determines the orientation of the trigger.


@export_file("*.tscn")
var target_level: String = ""
# Scene file that will load when player enters.


@export var target_area_name: String = "LevelTransition"
# Name of the spawn transition in the next level.



#        NODE REFERENCES
@onready var area_2d: Area2D = $Area2D
# Collision area used to detect player entry.



#        INITIALIZATION
func _ready() -> void:

	# Skip runtime logic when editing inside the editor.
	if Engine.is_editor_hint():
		return

	# Listen for scene transition events.
	SceneManager.new_scene_ready.connect(_on_new_scene_ready)
	SceneManager.load_scene_finished.connect(_on_load_scene_finished)

	# Detect when player enters the trigger.
	area_2d.body_entered.connect(_on_player_entered)

	pass


#        PLAYER ENTRY
func _on_player_entered(_n: Node2D) -> void:

	print("Entered transition")
	print("target_level = ", target_level)

	# Start scene transition.
	SceneManager.transition_scene(target_level, target_area_name, get_offset(_n), "left")

	# Debug confirmation.
	print("In")

	pass


#        PLAYER SPAWN POSITION
func _on_new_scene_ready(target_name: String, offset: Vector2) -> void:

	# Only activate if this transition is the target spawn point.
	if target_name != name:
		pass
		return

	# Find the persistent player.
	var player: Node2D = get_tree().get_first_node_in_group("Player")

	# Wait a few frames in case the player was deferred/reparented.
	var tries := 0

	while player == null and tries < 10:

		await get_tree().process_frame

		player = get_tree().get_first_node_in_group("Player")

		tries += 1


	# If player still missing, stop.
	if player == null:

		push_warning("Player not found in group 'Player'")

		pass
		return


	# Move player to this transition position.
	player.global_position = global_position + offset

	pass


#        SCENE FINISHED LOADING
func _on_load_scene_finished() -> void:

	# Safety check to avoid duplicate signal connections.
	if not area_2d.body_entered.is_connected(_on_player_entered):

		area_2d.body_entered.connect(_on_player_entered)

	pass


#        AREA CONFIGURATION
func apply_area_settings() -> void:

	var a: Area2D = get_node_or_null("Area2D")

	if not a:
		return

	# Vertical trigger (left/right doors).
	if location == SIDE.LEFT or location == SIDE.RIGHT:

		a.scale.y = size

		if location == SIDE.LEFT:
			a.scale.x = -1
		else:
			a.scale.x = 1

	# Horizontal trigger (top/bottom doors).
	else:

		a.scale.x = size

		if location == SIDE.TOP:
			a.scale.y = 1
		else:
			a.scale.y = -1

	pass


#        PLAYER OFFSET
# Calculates the spawn offset for the player based on transition direction.
# Used to slightly push the player away from the transition so they don't
# immediately re-trigger the Area2D.

func get_offset(player : Node2D) -> Vector2:
	var offset : Vector2 = Vector2.ZERO
	var player_pos : Vector2 = player.global_position

	if location == SIDE.LEFT or location == SIDE.RIGHT:
		offset.y = player_pos.y - self.global_position.y
		if location == SIDE.LEFT:
			offset.x = -12
		else:
			offset.x = 12
	else:
		offset.x = player_pos.x - self.global_position.x
		if location == SIDE.TOP:
			offset.y = -2
		else:
			offset.y = 48

	return offset
