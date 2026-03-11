# Title Screen
extends CanvasLayer

#region /// on ready variables
@onready var main_menu: VBoxContainer = $Control/MainMenu
@onready var new_game_menu: VBoxContainer = $Control/NewGameMenu
@onready var load_game_menu: VBoxContainer = $Control/LoadGameMenu

@onready var new_game_button: Button = $Control/MainMenu/NewGameButton
@onready var load_game_button: Button = $Control/MainMenu/LoadGameButton

@onready var new_slot_01: Button = $Control/NewGameMenu/NewSlot01
@onready var new_slot_02: Button = $Control/NewGameMenu/NewSlot02
@onready var new_slot_03: Button = $Control/NewGameMenu/NewSlot03

@onready var load_slot_01: Button = $Control/LoadGameMenu/LoadSlot01
@onready var load_slot_02: Button = $Control/LoadGameMenu/LoadSlot02
@onready var load_slot_03: Button = $Control/LoadGameMenu/LoadSlot03

@onready var animation_player: AnimationPlayer = get_node_or_null("Control/MainMenu/Logo/AnimationPlayer")
#endregion

# --- Track which heartbeat becomes default after click ---
var _default_heartbeat_set: bool = false

func _ready() -> void:
	# connect to button signals safely
	if new_game_button:
		new_game_button.pressed.connect(show_new_game_menu)
		new_game_button.mouse_entered.connect(_on_play_hover)
		new_game_button.mouse_exited.connect(_on_play_exit)
	if load_game_button:
		load_game_button.pressed.connect(show_load_game_menu)
		load_game_button.mouse_entered.connect(_on_play_hover)
		load_game_button.mouse_exited.connect(_on_play_exit)

	if new_slot_01:
		new_slot_01.pressed.connect(_on_new_game_pressed.bind(0))
		new_slot_01.mouse_entered.connect(_on_slot_hover.bind(0))
		new_slot_01.mouse_exited.connect(_on_slot_exit.bind(0))
	if new_slot_02:
		new_slot_02.pressed.connect(_on_new_game_pressed.bind(1))
		new_slot_02.mouse_entered.connect(_on_slot_hover.bind(1))
		new_slot_02.mouse_exited.connect(_on_slot_exit.bind(1))
	if new_slot_03:
		new_slot_03.pressed.connect(_on_new_game_pressed.bind(2))
		new_slot_03.mouse_entered.connect(_on_slot_hover.bind(2))
		new_slot_03.mouse_exited.connect(_on_slot_exit.bind(2))

	if load_slot_01:
		load_slot_01.pressed.connect(_on_load_game_pressed.bind(0))
		load_slot_01.mouse_entered.connect(_on_slot_hover.bind(0))
		load_slot_01.mouse_exited.connect(_on_slot_exit.bind(0))
	if load_slot_02:
		load_slot_02.pressed.connect(_on_load_game_pressed.bind(1))
		load_slot_02.mouse_entered.connect(_on_slot_hover.bind(1))
		load_slot_02.mouse_exited.connect(_on_slot_exit.bind(1))
	if load_slot_03:
		load_slot_03.pressed.connect(_on_load_game_pressed.bind(2))
		load_slot_03.mouse_entered.connect(_on_slot_hover.bind(2))
		load_slot_03.mouse_exited.connect(_on_slot_exit.bind(2))

	show_main_menu()

	if animation_player:
		animation_player.animation_finished.connect(_on_animation_finished)

	# --- Start heartbeat01 looping on game launch ---
	call_deferred("play_initial_heartbeat")
	pass

func play_initial_heartbeat():
	Audio.play_heartbeat_loop(0)  # HeartBeat01 plays on repeat

# --- BUTTON HOVER HANDLERS ---
func _on_play_hover():
	Audio.play_heartbeat_loop(1)  # HeartBeat02 while hovering Play

func _on_play_exit():
	if not _default_heartbeat_set:
		Audio.play_heartbeat_loop(0)  # revert to HeartBeat01 if nothing clicked

func _on_slot_hover(slot: int):
	Audio.play_heartbeat_loop(2)  # HeartBeat03 while hovering New/Load slots

func _on_slot_exit(slot: int):
	if not _default_heartbeat_set:
		Audio.play_heartbeat_loop(0)  # revert to HeartBeat01 if nothing clicked

# --- BUTTON CLICK HANDLERS ---
func _on_new_game_pressed(slot: int) -> void:
	SaveManager.create_new_game_save(slot)
	_default_heartbeat_set = true
	Audio.play_heartbeat_loop(2)  # HeartBeat03 becomes default after click

func _on_load_game_pressed(slot: int) -> void:
	# SaveManager.load_game(slot)
	_default_heartbeat_set = true
	Audio.play_heartbeat_loop(2)  # HeartBeat03 becomes default after click

# --- EXISTING MENU LOGIC BELOW ---
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if main_menu and not main_menu.visible:
			# audio
			show_main_menu()
	pass

func show_main_menu() -> void:
	if main_menu:
		main_menu.visible = true
	if new_game_menu:
		new_game_menu.visible = false
	if load_game_menu:
		load_game_menu.visible = false
	if new_game_button:
		new_game_button.grab_focus()
	pass

func show_new_game_menu() -> void:
	if main_menu:
		main_menu.visible = false
	if new_game_menu:
		new_game_menu.visible = true
	if load_game_menu:
		load_game_menu.visible = false

	if new_slot_01:
		new_slot_01.grab_focus()

	if SaveManager.save_file_exists(0) and new_slot_01:
		new_slot_01.text = "Replace Slot 01"
	if SaveManager.save_file_exists(1) and new_slot_02:
		new_slot_02.text = "Replace Slot 02"
	if SaveManager.save_file_exists(2) and new_slot_03:
		new_slot_03.text = "Replace Slot 03"
	pass

func show_load_game_menu() -> void:
	if main_menu:
		main_menu.visible = false
	if new_game_menu:
		new_game_menu.visible = false
	if load_game_menu:
		load_game_menu.visible = true

	if load_slot_01:
		load_slot_01.grab_focus()

	if load_slot_01:
		load_slot_01.disabled = not SaveManager.save_file_exists(0)
	if load_slot_02:
		load_slot_02.disabled = not SaveManager.save_file_exists(1)
	if load_slot_03:
		load_slot_03.disabled = not SaveManager.save_file_exists(2)
	pass

func _on_animation_finished(anim_name: String) -> void:
	if anim_name == "start" and animation_player:
		animation_player.play("loop")
	pass
