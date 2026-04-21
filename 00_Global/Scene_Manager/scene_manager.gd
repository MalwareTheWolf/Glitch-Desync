extends CanvasLayer

signal load_scene_started
signal new_scene_ready(target_data: Variant, offset: Vector2, transition_body: Node2D)
signal load_scene_finished
signal scene_entered(uid: String)

var current_scene_uid: String = ""
var carried_body: Node2D = null


func _ready() -> void:
	await get_tree().process_frame

	if get_tree().current_scene:
		current_scene_uid = get_tree().current_scene.scene_file_path

	load_scene_finished.emit()


func transition_scene(new_scene: String, target_data: Variant, player_offset: Vector2, _dir: String, body: Node2D = null) -> void:
	load_scene_started.emit()
	await get_tree().process_frame

	carried_body = null

	# Preserve the transitioning body across scene changes.
	if body != null and is_instance_valid(body):
		carried_body = body
		var root := get_tree().root

		if carried_body.get_parent() != root:
			carried_body.get_parent().remove_child(carried_body)
			root.add_child(carried_body)

	var err := get_tree().change_scene_to_file(new_scene)
	if err != OK:
		push_error("Failed to change scene: %s | err=%s" % [new_scene, err])
		return

	current_scene_uid = new_scene
	scene_entered.emit(current_scene_uid)

	await get_tree().scene_changed
	await get_tree().process_frame

	new_scene_ready.emit(target_data, player_offset, carried_body)
	load_scene_finished.emit()
