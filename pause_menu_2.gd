class_name PauseMenu
extends CanvasLayer
# Pause menu controller.
# Handles opening and closing the book, switching pages with tab buttons,
# and showing the current page content.


#region /// on ready variables
@onready var main_node: Control = $MainNode
@onready var book: AnimatedSprite2D = $MainNode/Book
@onready var animation_player: AnimationPlayer = $MainNode/AnimationPlayer

@onready var tabs: Control = $MainNode/Tabs
@onready var map_tab: Control = $MainNode/Tabs/Map
@onready var player_tab: Control = $MainNode/Tabs/PlayerStats
@onready var system_tab: Control = $MainNode/Tabs/System
@onready var spells_tab: Control = $MainNode/Tabs/Spells
@onready var inventory_tab: Control = $MainNode/Tabs/Inventory

@onready var map_button: BaseButton = $MainNode/Tabs/Map/MapButton
@onready var player_button: BaseButton = $MainNode/Tabs/PlayerStats/PlayerStatsButton
@onready var system_button: BaseButton = $MainNode/Tabs/System/SystemButton
@onready var spells_button: BaseButton = $MainNode/Tabs/Spells/SpellsButton
@onready var inventory_button: BaseButton = $MainNode/Tabs/Inventory/InventoryButton

@onready var pages: Control = $MainNode/Pages
@onready var map_page: Control = $MainNode/Pages/Map
@onready var player_page: Control = $MainNode/Pages/Player
@onready var system_page: Control = $MainNode/Pages/System
@onready var spells_page: Control = $MainNode/Pages/Spells
@onready var inventory_page: Control = $MainNode/Pages/Inventory
#endregion


#region /// standard variables
var current_page : String = "Player"
var is_open : bool = false
var is_turning_page : bool = false
#endregion


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().paused = true

	hide_all_pages()
	set_tab_buttons_enabled( false )

	map_button.pressed.connect( _on_map_pressed )
	player_button.pressed.connect( _on_player_pressed )
	system_button.pressed.connect( _on_system_pressed )
	spells_button.pressed.connect( _on_spells_pressed )
	inventory_button.pressed.connect( _on_inventory_pressed )

	if book.sprite_frames and book.sprite_frames.has_animation( "open" ):
		book.play( "open" )
		await book.animation_finished

	if book.sprite_frames and book.sprite_frames.has_animation( "tabs_appear" ):
		book.play( "tabs_appear" )
		await book.animation_finished

	is_open = true
	show_page( "Player" )
	set_tab_buttons_enabled( true )
	pass


func _unhandled_input( event: InputEvent ) -> void:
	if event.is_action_pressed( "pause" ):
		get_viewport().set_input_as_handled()
		close_pause_menu()
	pass


func hide_all_pages() -> void:
	hide_page_group( map_page )
	hide_page_group( player_page )
	hide_page_group( system_page )
	hide_page_group( spells_page )
	hide_page_group( inventory_page )
	pass


func hide_page_group( page_root : Control ) -> void:
	page_root.visible = false

	if page_root.has_node( "CurrentPage" ):
		page_root.get_node( "CurrentPage" ).visible = false

	for c in page_root.get_children():
		if c.name.contains( "Selected" ):
			c.visible = false
	pass


func show_page( page_name : String ) -> void:
	hide_all_pages()

	var page_root : Control = get_page_root( page_name )
	if page_root == null:
		return

	page_root.visible = true

	if page_root.has_node( "CurrentPage" ):
		page_root.get_node( "CurrentPage" ).visible = true

	for c in page_root.get_children():
		if c.name.contains( "Selected" ):
			c.visible = true

	current_page = page_name
	update_tab_states()
	pass


func get_page_root( page_name : String ) -> Control:
	if page_name == "Map":
		return map_page
	elif page_name == "Player":
		return player_page
	elif page_name == "System":
		return system_page
	elif page_name == "Spells":
		return spells_page
	elif page_name == "Inventory":
		return inventory_page

	return null


func set_tab_buttons_enabled( value : bool ) -> void:
	map_button.disabled = !value
	player_button.disabled = !value
	system_button.disabled = !value
	spells_button.disabled = !value
	inventory_button.disabled = !value
	pass


func update_tab_states() -> void:
	map_button.button_pressed = current_page == "Map"
	player_button.button_pressed = current_page == "Player"
	system_button.button_pressed = current_page == "System"
	spells_button.button_pressed = current_page == "Spells"
	inventory_button.button_pressed = current_page == "Inventory"
	pass


func turn_page( new_page : String ) -> void:
	if !is_open:
		return
	if is_turning_page:
		return
	if new_page == current_page:
		return

	is_turning_page = true
	set_tab_buttons_enabled( false )
	hide_all_pages()

	if should_flip_left( current_page, new_page ):
		if book.sprite_frames and book.sprite_frames.has_animation( "flip_left_3" ):
			book.play( "flip_left_3" )
			await book.animation_finished
		elif animation_player.has_animation( "flip_left" ):
			animation_player.play( "flip_left" )
			await animation_player.animation_finished
	else:
		if book.sprite_frames and book.sprite_frames.has_animation( "flip_right_2" ):
			book.play( "flip_right_2" )
			await book.animation_finished
		elif animation_player.has_animation( "flip_right" ):
			animation_player.play( "flip_right" )
			await animation_player.animation_finished

	show_page( new_page )
	set_tab_buttons_enabled( true )
	is_turning_page = false
	pass


func should_flip_left( from_page : String, to_page : String ) -> bool:
	var order : Array[String] = [ "Player", "Map", "Spells", "Inventory", "System" ]
	var from_index : int = order.find( from_page )
	var to_index : int = order.find( to_page )

	if from_index == -1 or to_index == -1:
		return false

	return to_index < from_index


func close_pause_menu() -> void:
	if !is_open:
		return
	if is_turning_page:
		return

	is_open = false
	set_tab_buttons_enabled( false )
	hide_all_pages()

	if book.sprite_frames and book.sprite_frames.has_animation( "tabs_disappear" ):
		book.play( "tabs_disappear" )
		await book.animation_finished

	if book.sprite_frames and book.sprite_frames.has_animation( "close" ):
		book.play( "close" )
		await book.animation_finished
	elif animation_player.has_animation( "close" ):
		animation_player.play( "close" )
		await animation_player.animation_finished

	get_tree().paused = false
	queue_free()
	pass


func _on_map_pressed() -> void:
	turn_page( "Map" )
	pass


func _on_player_pressed() -> void:
	turn_page( "Player" )
	pass


func _on_system_pressed() -> void:
	turn_page( "System" )
	pass


func _on_spells_pressed() -> void:
	turn_page( "Spells" )
	pass


func _on_inventory_pressed() -> void:
	turn_page( "Inventory" )
	pass
