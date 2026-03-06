extends CanvasLayer

signal load_scene_started
signal new_scene_ready(target_name: String, offset: Vector2)
signal load_scene_finished
signal scene_entered(uid: String)

var current_scene_uid: String = ""


func _ready() -> void:
	# wait one frame so the tree is fully alive
	await get_tree().process_frame

	# store the current scene path immediately so saving works before any transition
	if get_tree().current_scene:
		current_scene_uid = get_tree().current_scene.scene_file_path

	load_scene_finished.emit()
	pass


func transition_scene(new_scene: String, target_area: String, player_offset: Vector2, dir: String) -> void:
	load_scene_started.emit()

	# get out of the physics callback first
	await get_tree().process_frame

	print("transition_scene called with: ", new_scene)

	var err := get_tree().change_scene_to_file(new_scene)
	print("scene change err = ", err)

	if err != OK:
		push_error("Failed to change scene to: %s | err=%s" % [new_scene, err])
		return

	# keep track of the current scene
	current_scene_uid = new_scene
	scene_entered.emit(current_scene_uid)

	# wait until the new scene is actually active
	await get_tree().scene_changed

	# wait one more frame so the new scene nodes exist
	await get_tree().process_frame

	# tell the target transition to place the player
	new_scene_ready.emit(target_area, player_offset)

	load_scene_finished.emit()
	pass
