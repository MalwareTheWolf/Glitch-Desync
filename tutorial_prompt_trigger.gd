extends Area2D

enum PromptMode {
	IDLE,
	TAP,
	HOLD
}

# Keeps prompts from showing again during the same playthrough.
static var shown_prompts := {}

@export var prompt_id: String = "test_prompt"

@export var action_1: String = "jump"
@export var mode_1: PromptMode = PromptMode.TAP

@export var action_2: String = ""
@export var mode_2: PromptMode = PromptMode.IDLE

@export var description_text: String = "Jump"
@export var connector_text: String = "+"

@export var required_player_var: String = ""

# Time the game briefly resumes between button 1 and button 2.
@export var unfreeze_between_buttons_time: float = 0.2

@export var debug_prompt: bool = false

@onready var ui = $PromptUI
@onready var icon1 = $PromptUI/Control/Panel/ActionIcon1
@onready var icon2 = $PromptUI/Control/Panel/ActionIcon2
@onready var connector = $PromptUI/Control/Panel/ConnectorLabel
@onready var label = $PromptUI/Control/Panel/DescriptionLabel

var prompt_active: bool = false
var waiting_for_first_action: bool = false
var waiting_for_second_action: bool = false


func _ready() -> void:
	# Allows this trigger to keep receiving input while the tree is paused.
	process_mode = Node.PROCESS_MODE_ALWAYS
	ui.process_mode = Node.PROCESS_MODE_ALWAYS

	ui.visible = false
	body_entered.connect(_on_enter)


func _input(event: InputEvent) -> void:
	if not prompt_active:
		return

	# First button step.
	if waiting_for_first_action and event.is_action_pressed(action_1):
		_on_first_action_pressed()
		return

	# Second button step.
	if waiting_for_second_action and action_2.strip_edges() != "" and event.is_action_pressed(action_2):
		_on_second_action_pressed()
		return


func _on_enter(body: Node) -> void:
	if not body.is_in_group("Player"):
		return

	# Optional ability/unlock requirement.
	if required_player_var.strip_edges() != "":
		if not body.get(required_player_var):
			return

	# Do not show this prompt again during this playthrough.
	if shown_prompts.get(prompt_id, false):
		return

	shown_prompts[prompt_id] = true
	_start_prompt()


func _start_prompt() -> void:
	label.text = description_text

	icon1.visible = true
	icon1.set_button(action_1, mode_1)

	var has_second_action := action_2.strip_edges() != ""

	if has_second_action:
		# Hide the second input at first.
		# It will appear and animate after the first button is pressed.
		icon2.visible = false
		connector.visible = false
	else:
		icon2.visible = false
		connector.visible = false

	ui.visible = true
	prompt_active = true
	waiting_for_first_action = true
	waiting_for_second_action = false

	get_tree().paused = true

	if debug_prompt:
		print("[PromptTrigger] Showing prompt:", prompt_id)
		print("[PromptTrigger] Waiting for first action:", action_1)


func _on_first_action_pressed() -> void:
	waiting_for_first_action = false

	if debug_prompt:
		print("[PromptTrigger] First action pressed:", action_1)

	# One-button prompt: finish immediately.
	if action_2.strip_edges() == "":
		_finish_prompt()
		return

	# Two-button prompt:
	# briefly unpause, then re-pause and reveal/animate the second button.
	_run_between_button_pause()


func _run_between_button_pause() -> void:
	prompt_active = false
	get_tree().paused = false

	await get_tree().create_timer(unfreeze_between_buttons_time).timeout

	get_tree().paused = true
	prompt_active = true
	waiting_for_second_action = true

	_show_second_button()

	if debug_prompt:
		print("[PromptTrigger] Waiting for second action:", action_2)


func _show_second_button() -> void:
	connector.visible = true
	connector.text = connector_text

	icon2.visible = true
	icon2.set_button(action_2, mode_2)

	# Small pop animation so the second button feels intentionally revealed.
	icon2.scale = Vector2(0.65, 0.65)

	var tween := create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(icon2, "scale", Vector2.ONE, 0.15)


func _on_second_action_pressed() -> void:
	if debug_prompt:
		print("[PromptTrigger] Second action pressed:", action_2)

	_finish_prompt()


func _finish_prompt() -> void:
	prompt_active = false
	waiting_for_first_action = false
	waiting_for_second_action = false

	ui.visible = false
	get_tree().paused = false

	if debug_prompt:
		print("[PromptTrigger] Prompt finished:", prompt_id)
