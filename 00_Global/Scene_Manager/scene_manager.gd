extends CanvasLayer

signal load_scene_started
signal new_scene_ready(target_name: String, offset: Vector2)
signal load_scene_finished

func _ready() -> void:
	await get_tree().process_frame
	load_scene_finished.emit()
	pass

func transition_scene(new_scene: String, target_area: String, player_offset: Vector2, dir: String) -> void:
	load_scene_started.emit()
#fade new secene out
	get_tree().change_scene_to_file(new_scene)

	await get_tree().scene_changed

	new_scene_ready.emit(target_area, player_offset)
#fade new scene in
	load_scene_finished.emit()
	pass
