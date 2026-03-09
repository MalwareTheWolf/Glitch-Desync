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


func _ready() -> void:
	# connect to button signals safely
	if new_game_button:
		new_game_button.pressed.connect(show_new_game_menu)
	if load_game_button:
		load_game_button.pressed.connect(show_load_game_menu)

	if new_slot_01:
		new_slot_01.pressed.connect(_on_new_game_pressed.bind(0))
	if new_slot_02:
		new_slot_02.pressed.connect(_on_new_game_pressed.bind(1))
	if new_slot_03:
		new_slot_03.pressed.connect(_on_new_game_pressed.bind(2))

	if load_slot_01:
		load_slot_01.pressed.connect(_on_load_game_pressed.bind(0))
	if load_slot_02:
		load_slot_02.pressed.connect(_on_load_game_pressed.bind(1))
	if load_slot_03:
		load_slot_03.pressed.connect(_on_load_game_pressed.bind(2))

	#Audio.setup_button_audio( self )

	show_main_menu()

	if animation_player:
		animation_player.animation_finished.connect(_on_animation_finished)
	pass


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


func _on_new_game_pressed(slot: int) -> void:
	SaveManager.create_new_game_save(slot)
	pass


func _on_load_game_pressed(_slot: int) -> void:
	#SaveManager.load_game( _slot )
	pass


func _on_animation_finished(anim_name: String) -> void:
	if anim_name == "start" and animation_player:
		animation_player.play("loop")
	pass
