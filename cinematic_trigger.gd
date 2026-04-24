extends Area2D

@export var actor: Node2D

@export var actor_speed: float = 120.0
@export var idle_animation_name: String = "idle"
@export var run_animation_name: String = "run"
@export var idle_time_before_run: float = 0.5

@export var camera_focus_time: float = 0.75
@export var actor_follow_time: float = 1.5
@export var camera_hold_after_follow_time: float = 1.0
@export var camera_return_time: float = 0.75

@export var disappear_at_end: bool = true
@export var trigger_once: bool = true

@export var run_audio: AudioStream
@export var play_audio_when_run_starts: bool = true
@export var audio_bus: String = "SFX"

@onready var end_marker: Marker2D = $EndMarker

var player: Player
var camera: Camera2D
var audio_player: AudioStreamPlayer2D

var has_triggered: bool = false
var actor_running: bool = false
var actor_reached_end: bool = false


func _ready() -> void:
	body_entered.connect(_on_body_entered)

	audio_player = AudioStreamPlayer2D.new()
	add_child(audio_player)
	audio_player.bus = audio_bus


func _physics_process(delta: float) -> void:
	if not actor_running or actor == null:
		return

	var target_position := end_marker.global_position
	var direction := actor.global_position.direction_to(target_position)

	actor.global_position += direction * actor_speed * delta
	_flip_actor_sprite(direction)

	if actor.global_position.distance_to(target_position) <= 5.0:
		actor.global_position = target_position
		actor_running = false
		actor_reached_end = true


func _on_body_entered(body: Node) -> void:
	if trigger_once and has_triggered:
		return

	if not body.is_in_group("Player"):
		return

	has_triggered = true
	start_sequence()


func start_sequence() -> void:
	player = get_tree().get_first_node_in_group("Player") as Player

	if player != null:
		camera = player.get_node_or_null("Camera2D") as Camera2D

	if actor == null or player == null or camera == null:
		push_warning("CinematicTrigger missing actor, player, or camera.")
		return

	player.set_control_enabled(false)

	await _move_camera_to(actor.global_position, camera_focus_time)

	await _play_idle_then_run()

	actor_reached_end = false
	actor_running = true

	if play_audio_when_run_starts:
		play_trigger_audio()

	await _follow_actor_for_time(actor_follow_time)

	await get_tree().create_timer(camera_hold_after_follow_time).timeout

	await _wait_for_actor_to_reach_end()

	if disappear_at_end and actor:
		actor.visible = false

	await _move_camera_to(player.global_position, camera_return_time)

	player.set_control_enabled(true)

	if trigger_once:
		monitoring = false


func _move_camera_to(target_position: Vector2, duration: float) -> void:
	var tween := create_tween()
	tween.tween_property(camera, "global_position", target_position, duration)
	await tween.finished


func _follow_actor_for_time(duration: float) -> void:
	var timer := 0.0

	while timer < duration and actor != null:
		camera.global_position = actor.global_position
		timer += get_process_delta_time()
		await get_tree().process_frame


func _wait_for_actor_to_reach_end() -> void:
	while not actor_reached_end:
		await get_tree().process_frame


func _play_idle_then_run() -> void:
	var anim := actor.get_node_or_null("AnimationPlayer") as AnimationPlayer

	if anim == null:
		return

	if anim.has_animation(idle_animation_name):
		anim.play(idle_animation_name)

	await get_tree().create_timer(idle_time_before_run).timeout

	if anim.has_animation(run_animation_name):
		anim.play(run_animation_name)


func _flip_actor_sprite(direction: Vector2) -> void:
	var sprite := actor.get_node_or_null("Sprite2D") as Sprite2D

	if sprite == null:
		return

	if direction.x == 0.0:
		return

	sprite.flip_h = direction.x > 0.0


func play_trigger_audio() -> void:
	if run_audio == null:
		return

	audio_player.stream = run_audio
	audio_player.global_position = actor.global_position if actor != null else global_position
	audio_player.play()
