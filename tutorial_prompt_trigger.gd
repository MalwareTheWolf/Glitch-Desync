extends Area2D

enum PromptMode {
	IDLE,
	TAP,
	HOLD
}

static var shown_prompts := {}

@export var prompt_id: String = "test_prompt"

@export var action_1: String = "jump"
@export var mode_1: PromptMode = PromptMode.TAP

@export var action_2: String = ""
@export var mode_2: PromptMode = PromptMode.IDLE

@export var description_text: String = "Jump"
@export var connector_text: String = "+"

@export var required_player_var: String = ""
@export var debug_prompt: bool = true

@onready var ui = $PromptUI
@onready var icon1 = $PromptUI/Control/Panel/ActionIcon1
@onready var icon2 = $PromptUI/Control/Panel/ActionIcon2
@onready var connector = $PromptUI/Control/Panel/ConnectorLabel
@onready var label = $PromptUI/Control/Panel/DescriptionLabel

var prompt_active: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	ui.process_mode = Node.PROCESS_MODE_ALWAYS

	ui.visible = false

	body_entered.connect(_on_enter)

	if debug_prompt:
		print("[PromptTrigger] READY")
		print("[PromptTrigger] prompt_id:", prompt_id)
		print("[PromptTrigger] action_1:", action_1)
		print("[PromptTrigger] action_2:", action_2)


func _input(event: InputEvent) -> void:
	if not prompt_active:
		return

	if event.is_action_pressed(action_1):
		if debug_prompt:
			print("[PromptTrigger] pressed action_1:", action_1)
		_finish_prompt()
		return

	if action_2.strip_edges() != "" and event.is_action_pressed(action_2):
		if debug_prompt:
			print("[PromptTrigger] pressed action_2:", action_2)
		_finish_prompt()
		return


func _on_enter(body: Node) -> void:
	if debug_prompt:
		print("[PromptTrigger] Something entered:", body.name)
		print("[PromptTrigger] Body groups:", body.get_groups())

	if not body.is_in_group("Player"):
		if debug_prompt:
			print("[PromptTrigger] ❌ Not Player")
		return

	if required_player_var.strip_edges() != "":
		if not body.get(required_player_var):
			if debug_prompt:
				print("[PromptTrigger] ❌ Missing ability/player var:", required_player_var)
			return

	if shown_prompts.get(prompt_id, false):
		if debug_prompt:
			print("[PromptTrigger] ❌ Already shown:", prompt_id)
		return

	shown_prompts[prompt_id] = true

	if debug_prompt:
		print("[PromptTrigger] ✅ Showing prompt:", prompt_id)

	label.text = description_text

	icon1.visible = true
	icon1.set_button(action_1, mode_1)

	if action_2.strip_edges() != "":
		icon2.visible = true
		connector.visible = true
		connector.text = connector_text
		icon2.set_button(action_2, mode_2)
	else:
		icon2.visible = false
		connector.visible = false

	ui.visible = true
	prompt_active = true

	get_tree().paused = true

	if debug_prompt:
		print("[PromptTrigger] Game paused. Waiting for:", action_1, action_2)


func _finish_prompt() -> void:
	prompt_active = false
	ui.visible = false
	get_tree().paused = false

	if debug_prompt:
		print("[PromptTrigger] ✅ Prompt finished. Game unpaused.")
