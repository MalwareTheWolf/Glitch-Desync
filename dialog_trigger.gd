extends Area2D

signal dialog_finished(dialog_id: String)

@export var dialog_id: String = "dialog_test"

@export var speaker_name: String = ""
@export_multiline var dialog_lines: Array[String] = []

@export var advance_action: String = "jump"
@export var show_once: bool = true
@export var lock_player: bool = true
@export var pause_game: bool = true

@onready var ui = $DialogUI
@onready var speaker_label = $DialogUI/Control/Panel/SpeakerLabel
@onready var body_label = $DialogUI/Control/Panel/BodyLabel

var player: Player
var active: bool = false
var line_index: int = 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	ui.process_mode = Node.PROCESS_MODE_ALWAYS

	ui.visible = false
	body_entered.connect(_on_enter)


func _input(event: InputEvent) -> void:
	if not active:
		return

	if event.is_action_pressed(advance_action):
		_next_line()


func _on_enter(body: Node) -> void:
	if not body.is_in_group("Player"):
		return

	if show_once and SaveManager.has_flag("dialog_" + dialog_id):
		return

	player = body as Player
	_start_dialog()


func _start_dialog() -> void:
	active = true
	line_index = 0

	if speaker_label:
		speaker_label.text = speaker_name

	ui.visible = true

	if lock_player and player:
		player.set_control_enabled(false)

	if pause_game:
		get_tree().paused = true

	_show_line()


func _show_line() -> void:
	if line_index >= dialog_lines.size():
		_finish_dialog()
		return

	body_label.text = dialog_lines[line_index]


func _next_line() -> void:
	line_index += 1
	_show_line()


func _finish_dialog() -> void:
	active = false
	ui.visible = false

	if pause_game:
		get_tree().paused = false

	if lock_player and player:
		player.set_control_enabled(true)

	if show_once:
		SaveManager.set_flag("dialog_" + dialog_id, true)

	dialog_finished.emit(dialog_id)
