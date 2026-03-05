extends CanvasLayer
# Global scene transition controller.
# Handles scene switching and player spawn positioning.



#        SIGNALS

signal load_scene_started
# Emitted when a transition begins (fade out UI can listen).

signal new_scene_ready(target_name: String, offset: Vector2)
# Emitted after the new scene loads so spawn points can place the player.

signal load_scene_finished
# Emitted after everything is ready (fade in UI can listen).



#        INITIALIZATION

func _ready() -> void:

	# Wait one frame so the scene tree fully initializes.
	await get_tree().process_frame

	# Notify listeners that the first scene is ready.
	load_scene_finished.emit()

	pass



#        SCENE TRANSITION

func transition_scene(new_scene: String, target_area: String, player_offset: Vector2, dir: String) -> void:

	# Notify listeners that transition has started.
	load_scene_started.emit()

	# Change scene safely (not during physics callback).
	get_tree().call_deferred("change_scene_to_file", new_scene)

	# Wait until the new scene is loaded.
	await get_tree().scene_changed

	# Wait one frame so nodes in the new scene exist.
	await get_tree().process_frame

	# Tell spawn points to position the player.
	new_scene_ready.emit(target_area, player_offset)

	# Notify listeners that transition is complete.
	load_scene_finished.emit()

	pass
