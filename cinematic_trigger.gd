extends Area2D

enum CutsceneMode {
	RUN_AWAY,
	AUDIO_ONLY,
	ATTACK_AND_EXIT
}

enum ActorChoice {
	ACTOR,
	SECONDARY_ACTOR
}

@export var cutscene_mode: CutsceneMode = CutsceneMode.RUN_AWAY

@export var actor: Node2D
@export var secondary_actor: Node2D

@export var camera_target: ActorChoice = ActorChoice.ACTOR
@export var exit_actor: ActorChoice = ActorChoice.ACTOR

@export var actor_speed: float = 120.0
@export var secondary_actor_speed: float = 90.0

@export var idle_animation_name: String = "idle"
@export var run_animation_name: String = "run"
@export var death_animation_name: String = "death"
@export var attack_animation_name: String = "holy_slash"
@export var walk_animation_name: String = "run"

@export var idle_time_before_run: float = 0.5
@export var camera_focus_time: float = 0.75
@export var actor_follow_time: float = 1.5
@export var camera_hold_after_follow_time: float = 1.0
@export var camera_return_time: float = 0.75

@export var flip_actor_before_death: bool = false
@export var flip_secondary_before_attack: bool = false
@export var flip_secondary_after_attack: bool = true
@export var flip_exit_actor_while_moving: bool = true
@export var invert_exit_flip: bool = true

@export var secondary_attack_y_offset: float = -30.0

@export var disappear_at_end: bool = true
@export var trigger_once: bool = true

@export var run_audio: AudioStream
@export var death_audio: AudioStream
@export var play_audio_when_run_starts: bool = true
@export var audio_bus: String = "SFX"

@onready var end_marker: Marker2D = $EndMarker

var player: Player
var camera: Camera2D
var audio_player: AudioStreamPlayer2D

var has_triggered: bool = false
var moving_node: Node2D
var moving_speed: float = 0.0
var actor_running: bool = false
var actor_reached_end: bool = false


func _ready() -> void:
	body_entered.connect(_on_body_entered)

	audio_player = AudioStreamPlayer2D.new()
	add_child(audio_player)
	audio_player.bus = audio_bus


func _physics_process(delta: float) -> void:
	if not actor_running or moving_node == null:
		return

	var target_position := end_marker.global_position
	var direction := moving_node.global_position.direction_to(target_position)

	moving_node.global_position += direction * moving_speed * delta

	if flip_exit_actor_while_moving:
		_flip_sprite_to_direction(moving_node, direction)

	if moving_node.global_position.distance_to(target_position) <= 5.0:
		moving_node.global_position = target_position
		actor_running = false
		actor_reached_end = true


func _on_body_entered(body: Node) -> void:
	if trigger_once and has_triggered:
		return

	if not body.is_in_group("Player"):
		return

	has_triggered = true

	match cutscene_mode:
		CutsceneMode.AUDIO_ONLY:
			play_audio(run_audio, global_position)

			if trigger_once:
				monitoring = false

		CutsceneMode.RUN_AWAY:
			start_run_away_sequence()

		CutsceneMode.ATTACK_AND_EXIT:
			start_attack_and_exit_sequence()


func _setup_player_and_camera() -> bool:
	player = get_tree().get_first_node_in_group("Player") as Player

	if player != null:
		camera = player.get_node_or_null("Camera2D") as Camera2D

	if player == null or camera == null:
		push_warning("CinematicTrigger missing player or camera.")
		return false

	return true


func start_run_away_sequence() -> void:
	if not _setup_player_and_camera():
		return

	if actor == null:
		push_warning("RUN_AWAY needs Actor.")
		return

	player.set_control_enabled(false)

	await _move_camera_to(actor.global_position, camera_focus_time)
	await _play_idle_then_run(actor)

	actor_reached_end = false
	moving_node = actor
	moving_speed = actor_speed
	actor_running = true

	if play_audio_when_run_starts:
		play_audio(run_audio, actor.global_position)

	await _follow_node_for_time(actor, actor_follow_time)
	await get_tree().create_timer(camera_hold_after_follow_time).timeout
	await _wait_for_actor_to_reach_end()

	if disappear_at_end and actor:
		actor.visible = false

	await _move_camera_to(player.global_position, camera_return_time)

	player.set_control_enabled(true)

	if trigger_once:
		monitoring = false


func start_attack_and_exit_sequence() -> void:
	if not _setup_player_and_camera():
		return

	if actor == null or secondary_actor == null:
		push_warning("ATTACK_AND_EXIT needs Actor and Secondary Actor.")
		return

	var focus_node := _get_actor_choice(camera_target)
	var exiting_node := _get_actor_choice(exit_actor)

	if focus_node == null or exiting_node == null:
		push_warning("Invalid camera target or exit actor.")
		return

	player.set_control_enabled(false)

	await _move_camera_to(focus_node.global_position, camera_focus_time)

	if flip_secondary_before_attack:
		_flip_sprite(secondary_actor)

	if flip_actor_before_death:
		_flip_sprite(actor)

	_set_sprite_y_offset(secondary_actor, secondary_attack_y_offset)

	await _play_animation(secondary_actor, attack_animation_name)

	if flip_secondary_after_attack:
		_flip_sprite(secondary_actor)

	await _play_animation(actor, death_animation_name)

	play_audio(death_audio, actor.global_position)

	actor_reached_end = false
	moving_node = exiting_node
	moving_speed = secondary_actor_speed if exiting_node == secondary_actor else actor_speed

	_play_animation_no_wait(exiting_node, walk_animation_name)
	_set_sprite_y_offset(secondary_actor, 0.0)

	actor_running = true

	await _follow_node_for_time(exiting_node, actor_follow_time)
	await get_tree().create_timer(camera_hold_after_follow_time).timeout
	await _wait_for_actor_to_reach_end()

	if disappear_at_end and exiting_node:
		exiting_node.visible = false

	await _move_camera_to(player.global_position, camera_return_time)

	player.set_control_enabled(true)

	if trigger_once:
		monitoring = false


func _get_actor_choice(choice: ActorChoice) -> Node2D:
	match choice:
		ActorChoice.ACTOR:
			return actor
		ActorChoice.SECONDARY_ACTOR:
			return secondary_actor

	return null


func _play_idle_then_run(target: Node2D) -> void:
	_play_animation_no_wait(target, idle_animation_name)

	await get_tree().create_timer(idle_time_before_run).timeout

	_play_animation_no_wait(target, run_animation_name)


func _play_animation(target: Node2D, animation_name: String) -> void:
	if target == null:
		return

	var anim_player := target.get_node_or_null("AnimationPlayer") as AnimationPlayer
	if anim_player and anim_player.has_animation(animation_name):
		anim_player.play(animation_name)
		await anim_player.animation_finished
		return

	var animated_sprite := target.get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D
	if animated_sprite and animated_sprite.sprite_frames and animated_sprite.sprite_frames.has_animation(animation_name):
		animated_sprite.play(animation_name)
		await animated_sprite.animation_finished
		return


func _play_animation_no_wait(target: Node2D, animation_name: String) -> void:
	if target == null:
		return

	var anim_player := target.get_node_or_null("AnimationPlayer") as AnimationPlayer
	if anim_player and anim_player.has_animation(animation_name):
		anim_player.play(animation_name)
		return

	var animated_sprite := target.get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D
	if animated_sprite and animated_sprite.sprite_frames and animated_sprite.sprite_frames.has_animation(animation_name):
		animated_sprite.play(animation_name)
		return


func _move_camera_to(target_position: Vector2, duration: float) -> void:
	var tween := create_tween()
	tween.tween_property(camera, "global_position", target_position, duration)
	await tween.finished


func _follow_node_for_time(target: Node2D, duration: float) -> void:
	var timer := 0.0

	while timer < duration and target != null:
		camera.global_position = target.global_position
		timer += get_process_delta_time()
		await get_tree().process_frame


func _wait_for_actor_to_reach_end() -> void:
	while not actor_reached_end:
		await get_tree().process_frame


func _flip_sprite(target: Node2D) -> void:
	if target == null:
		return

	var sprite := target.get_node_or_null("Sprite2D") as Sprite2D
	if sprite:
		sprite.flip_h = not sprite.flip_h
		return

	var animated_sprite := target.get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D
	if animated_sprite:
		animated_sprite.flip_h = not animated_sprite.flip_h


func _flip_sprite_to_direction(target: Node2D, direction: Vector2) -> void:
	if target == null or direction.x == 0.0:
		return

	var should_flip := direction.x > 0.0

	if invert_exit_flip:
		should_flip = not should_flip

	var sprite := target.get_node_or_null("Sprite2D") as Sprite2D
	if sprite:
		sprite.flip_h = should_flip
		return

	var animated_sprite := target.get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D
	if animated_sprite:
		animated_sprite.flip_h = should_flip


func _set_sprite_y_offset(target: Node2D, offset: float) -> void:
	if target == null:
		return

	var sprite := target.get_node_or_null("Sprite2D") as Sprite2D
	if sprite:
		sprite.position.y = offset
		return

	var animated_sprite := target.get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D
	if animated_sprite:
		animated_sprite.position.y = offset


func play_audio(stream: AudioStream, at_position: Vector2) -> void:
	if stream == null:
		return

	audio_player.stream = stream
	audio_player.global_position = at_position
	audio_player.play()
