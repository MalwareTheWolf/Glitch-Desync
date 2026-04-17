class_name PauseMenuBook
extends CanvasLayer

# Main UI references.
@onready var main_node: Control = $MainNode
@onready var book: AnimatedSprite2D = $MainNode/Book
@onready var pages: Control = $MainNode/Pages
@onready var tabs: Control = $MainNode/Tabs

# Main pages.
@onready var map_page: Control = $MainNode/Pages/Map
@onready var player_page: Control = $MainNode/Pages/Player
@onready var system_page: Control = $MainNode/Pages/System
@onready var spells_page: Control = $MainNode/Pages/Spells
@onready var inventory_page: Control = $MainNode/Pages/Inventory

# System tabs.
@onready var system_tabs: TabContainer = $MainNode/Pages/System/TabContainer

# System section buttons.
@onready var audio_button: BaseButton = $MainNode/Pages/System/Settings_Sections/Audio_Button
@onready var video_button: BaseButton = $MainNode/Pages/System/Settings_Sections/Video_Button
@onready var graphics_button: BaseButton = $MainNode/Pages/System/Settings_Sections/Graphics_Button
@onready var controls_button: BaseButton = $MainNode/Pages/System/Settings_Sections/Controls_Button

# Main tab buttons.
@onready var map_button: BaseButton = $MainNode/Tabs/Map/MapButton
@onready var player_button: BaseButton = $MainNode/Tabs/PlayerStats/PlayerStatsButton
@onready var system_button: BaseButton = $MainNode/Tabs/System/SystemButton
@onready var spells_button: BaseButton = $MainNode/Tabs/Spells/SpellsButton
@onready var inventory_button: BaseButton = $MainNode/Tabs/Inventory/InventoryButton

# Current menu state.
@export_enum("Map", "Player", "System", "Spells", "Inventory") var default_page: String = "Player"

var current_page: String = "Player"
var is_open: bool = false
var is_turning_page: bool = false
var is_closing: bool = false



#LIFECYCLE

func _ready() -> void:

	# Allow UI to process while the game is paused.
	process_mode = Node.PROCESS_MODE_ALWAYS
	main_node.process_mode = Node.PROCESS_MODE_ALWAYS
	pages.process_mode = Node.PROCESS_MODE_ALWAYS
	tabs.process_mode = Node.PROCESS_MODE_ALWAYS
	book.process_mode = Node.PROCESS_MODE_ALWAYS

	# Pause gameplay while the menu is open.
	get_tree().paused = true

	# Start with only the animated book visible.
	pages.visible = false
	tabs.visible = false
	book.visible = true

	hide_all_pages()
	set_tab_buttons_enabled(false)
	connect_buttons()

	await play_open_sequence()



#INPUT

func _input(event: InputEvent) -> void:

	# Use a rect fallback so the Spells tab still opens
	# even if another overlapping control steals the click.
	if _handle_tab_click_fallback(event):
		return

	# Close the pause menu with the pause input.
	if event.is_action_pressed("pause"):
		get_viewport().set_input_as_handled()
		close_pause_menu()


# Handles left click page switching based on tab button screen rects.
func _handle_tab_click_fallback(event: InputEvent) -> bool:
	if not is_open or is_turning_page or is_closing:
		return false

	if event is not InputEventMouseButton:
		return false

	var mb := event as InputEventMouseButton
	if mb.button_index != MOUSE_BUTTON_LEFT or not mb.pressed:
		return false

	var mouse_pos: Vector2 = get_viewport().get_mouse_position()

	if spells_button and spells_button.visible and not spells_button.disabled:
		if spells_button.get_global_rect().has_point(mouse_pos):
			get_viewport().set_input_as_handled()
			turn_page("Spells")
			return true

	if map_button and map_button.visible and not map_button.disabled:
		if map_button.get_global_rect().has_point(mouse_pos):
			get_viewport().set_input_as_handled()
			turn_page("Map")
			return true

	if player_button and player_button.visible and not player_button.disabled:
		if player_button.get_global_rect().has_point(mouse_pos):
			get_viewport().set_input_as_handled()
			turn_page("Player")
			return true

	if inventory_button and inventory_button.visible and not inventory_button.disabled:
		if inventory_button.get_global_rect().has_point(mouse_pos):
			get_viewport().set_input_as_handled()
			turn_page("Inventory")
			return true

	if system_button and system_button.visible and not system_button.disabled:
		if system_button.get_global_rect().has_point(mouse_pos):
			get_viewport().set_input_as_handled()
			turn_page("System")
			return true

	return false



#CONNECTIONS

# Connects all button signals.
func connect_buttons() -> void:

	if map_button and not map_button.pressed.is_connected(_on_map_pressed):
		map_button.pressed.connect(_on_map_pressed)

	if player_button and not player_button.pressed.is_connected(_on_player_pressed):
		player_button.pressed.connect(_on_player_pressed)

	if system_button and not system_button.pressed.is_connected(_on_system_pressed):
		system_button.pressed.connect(_on_system_pressed)

	if spells_button and not spells_button.pressed.is_connected(_on_spells_pressed):
		spells_button.pressed.connect(_on_spells_pressed)

	if inventory_button and not inventory_button.pressed.is_connected(_on_inventory_pressed):
		inventory_button.pressed.connect(_on_inventory_pressed)

	if audio_button and not audio_button.pressed.is_connected(_on_audio_pressed):
		audio_button.pressed.connect(_on_audio_pressed)

	if video_button and not video_button.pressed.is_connected(_on_video_pressed):
		video_button.pressed.connect(_on_video_pressed)

	if graphics_button and not graphics_button.pressed.is_connected(_on_graphics_pressed):
		graphics_button.pressed.connect(_on_graphics_pressed)

	if controls_button and not controls_button.pressed.is_connected(_on_controls_pressed):
		controls_button.pressed.connect(_on_controls_pressed)



#OPEN / CLOSE

# Plays opening animation sequence.
func play_open_sequence() -> void:

	if book.sprite_frames and book.sprite_frames.has_animation("open"):
		book.play("open")
		await book.animation_finished

	if book.sprite_frames and book.sprite_frames.has_animation("tabs_appear"):
		book.play("tabs_appear")
		await book.animation_finished

	book.visible = false
	pages.visible = true
	tabs.visible = true

	is_open = true
	show_page(default_page)
	set_tab_buttons_enabled(true)


# Closes the menu and unpauses the game.
func close_pause_menu() -> void:

	if not is_open or is_turning_page or is_closing:
		return

	is_closing = true
	set_tab_buttons_enabled(false)

	pages.visible = false
	tabs.visible = false
	book.visible = true

	if book.sprite_frames and book.sprite_frames.has_animation("tabs_disappear"):
		book.play("tabs_disappear")
		await book.animation_finished

	if book.sprite_frames and book.sprite_frames.has_animation("close"):
		book.play("close")
		await book.animation_finished

	get_tree().paused = false
	queue_free()



#PAGE CONTROL

# Hides all main pages.
func hide_all_pages() -> void:
	for page in pages.get_children():
		page.visible = false


# Shows one page.
func show_page(page_name: String) -> void:

	hide_all_pages()

	match page_name:
		"Map":
			map_page.visible = true
			if map_page.has_method("refresh_page"):
				map_page.refresh_page()

		"Player":
			player_page.visible = true

		"System":
			system_page.visible = true
			if system_tabs:
				system_tabs.current_tab = 0

		"Spells":
			spells_page.visible = true
			if spells_page.has_method("refresh_ability_list"):
				spells_page.refresh_ability_list()

		"Inventory":
			inventory_page.visible = true

	current_page = page_name


# Enables or disables main tab buttons.
func set_tab_buttons_enabled(value: bool) -> void:

	if map_button:
		map_button.disabled = not value

	if player_button:
		player_button.disabled = not value

	if system_button:
		system_button.disabled = not value

	if spells_button:
		spells_button.disabled = not value

	if inventory_button:
		inventory_button.disabled = not value



#PAGE TURNING

# Turns to a different page with animation.
func turn_page(new_page: String) -> void:

	if not is_open or is_turning_page or is_closing or new_page == current_page:
		return

	is_turning_page = true
	set_tab_buttons_enabled(false)

	pages.visible = false
	tabs.visible = false
	book.visible = true

	if should_flip_left(current_page, new_page):
		if book.sprite_frames and book.sprite_frames.has_animation("flip_left_3"):
			book.play("flip_left_3")
			await book.animation_finished
	else:
		if book.sprite_frames and book.sprite_frames.has_animation("flip_right_2"):
			book.play("flip_right_2")
			await book.animation_finished

	book.visible = false
	pages.visible = true
	tabs.visible = true

	show_page(new_page)
	set_tab_buttons_enabled(true)
	is_turning_page = false


# Determines which page turn animation direction to use.
func should_flip_left(from_page: String, to_page: String) -> bool:
	var order: Array[String] = ["Player", "Map", "Spells", "Inventory", "System"]
	return order.find(to_page) < order.find(from_page)



#TAB CALLBACKS

func _on_map_pressed() -> void:
	turn_page("Map")


func _on_player_pressed() -> void:
	turn_page("Player")


func _on_system_pressed() -> void:
	turn_page("System")


func _on_spells_pressed() -> void:
	turn_page("Spells")


func _on_inventory_pressed() -> void:
	turn_page("Inventory")



#SYSTEM SUBPAGE CALLBACKS

func _on_audio_pressed() -> void:
	if system_tabs:
		system_tabs.current_tab = 0


func _on_video_pressed() -> void:
	if system_tabs:
		system_tabs.current_tab = 1


func _on_graphics_pressed() -> void:
	if system_tabs:
		system_tabs.current_tab = 2


func _on_controls_pressed() -> void:
	if system_tabs:
		system_tabs.current_tab = 3
