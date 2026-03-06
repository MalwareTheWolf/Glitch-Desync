# SceneManager
extends CanvasLayer

# Signals for scene transitions
signal load_scene_started
signal new_scene_ready(target_name: String, offset: Vector2)
signal load_scene_finished
signal scene_entered(uid: String)

# Tracks the UID/path of the current scene
var current_scene_uid: String = ""


func _ready() -> void:
	# wait one frame so the tree is fully alive
	await get_tree().process_frame

	# store the current scene path immediately so saving works before any transition
	if get_tree().current_scene:
		current_scene_uid = get_tree().current_scene.scene_file_path

	# emit finished loading the initial scene
	load_scene_finished.emit()
	pass


func transition_scene(new_scene: String, target_area: String, player_offset: Vector2, dir: String) -> void:
	load_scene_started.emit()

	# wait one frame to get out of any physics callbacks
	await get_tree().process_frame

	print("transition_scene called with: ", new_scene)

	# change to the new scene
	var err := get_tree().change_scene_to_file(new_scene)
	if err != OK:
		push_error("Failed to change scene to: %s | err=%s" % [new_scene, err])
		return

	# update current scene UID
	current_scene_uid = new_scene
	scene_entered.emit(current_scene_uid)

	# wait until the new scene is active
	await get_tree().scene_changed

	# wait one more frame so all nodes in the new scene are ready
	await get_tree().process_frame

	# emit signal so things like the player can be positioned
	new_scene_ready.emit(target_area, player_offset)

	# emit that the transition is finished
	load_scene_finished.emit()
	pass
