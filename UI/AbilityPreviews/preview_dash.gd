extends Node2D

@onready var actor = $PreviewActor
@onready var start_point: Marker2D = $StartPoint
@onready var end_point: Marker2D = $EndPoint

const PRE_DASH_DELAY: float = 1.5
const DASH_STARTUP_DELAY: float = 0.08
const POST_DASH_IDLE_DELAY: float = 1.5
const DASH_ANIM_SPEED: float = 2
const DASH_MOVE_TIME: float = 0.35
const GHOST_INTERVAL: float = 0.05


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	call_deferred("_loop_preview")


func _loop_preview() -> void:
	while true:
		await _play_dash_preview()


func _play_dash_preview() -> void:
	if actor == null or start_point == null or end_point == null:
		return

	# Reset to start and stay idle
	actor.reset_actor(start_point.position)
	actor.play_anim("idle", 1.0)
	await get_tree().create_timer(PRE_DASH_DELAY, true, false, true).timeout

	# Start dash animation first
	actor.play_anim("dash", DASH_ANIM_SPEED)

	# Tiny delay so dash visibly begins before movement
	await get_tree().create_timer(DASH_STARTUP_DELAY, true, false, true).timeout

	# Spawn ghosts during movement, but don't block the sequence
	_spawn_ghosts()

	# Now move
	var tween := create_tween()
	tween.tween_property(actor, "position", end_point.position, DASH_MOVE_TIME) \
		.set_trans(Tween.TRANS_QUAD) \
		.set_ease(Tween.EASE_OUT)

	await tween.finished

	# Force idle after dash finishes
	actor.play_anim("idle", 1.0)

	# Stay idle at the end so the loop is obvious
	await get_tree().create_timer(POST_DASH_IDLE_DELAY, true, false, true).timeout


func _spawn_ghosts() -> void:
	call_deferred("_ghost_loop")


func _ghost_loop() -> void:
	var elapsed: float = 0.0

	while elapsed < DASH_MOVE_TIME:
		_spawn_ghost()
		await get_tree().create_timer(GHOST_INTERVAL, true, false, true).timeout
		elapsed += GHOST_INTERVAL


func _spawn_ghost() -> void:
	if actor == null or actor.sprite == null:
		return

	var ghost := Sprite2D.new()
	ghost.texture = actor.sprite.texture
	ghost.hframes = actor.sprite.hframes
	ghost.vframes = actor.sprite.vframes
	ghost.frame = actor.sprite.frame
	ghost.frame_coords = actor.sprite.frame_coords
	ghost.flip_h = actor.sprite.flip_h
	ghost.position = actor.position
	ghost.scale = actor.sprite.scale
	ghost.rotation = actor.sprite.rotation
	ghost.centered = actor.sprite.centered
	ghost.offset = actor.sprite.offset
	ghost.modulate = Color(1.0, 1.0, 1.0, 0.35)

	add_child(ghost)

	var tween := create_tween()
	tween.tween_property(ghost, "modulate:a", 0.0, 0.18)
	tween.tween_callback(ghost.queue_free)
