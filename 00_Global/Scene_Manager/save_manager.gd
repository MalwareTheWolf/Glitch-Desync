extends Node
# SaveManager script.
# Handles creating save files, writing save data, loading save data,
# restoring the player after scene transitions, and managing discovered areas and config.


#region /// constants
const CONFIG_FILE_PATH = "user://settings.cfg"
# Path to config file for audio and other settings.

const DEFAULT_SCENE_PATH : String = "res://World/00_Void/01.tscn"
# First scene when starting a new game.

const SLOTS: Array[String] = [
	"save_01",
	"save_02",
	"save_03"
]
# Save slot file names.
#endregion


#region /// variables
var current_slot: int = 0
var save_data: Dictionary
var discovered_areas: Array = []
var persistent_data: Dictionary = {}
#endregion


func _ready() -> void:
	# Load saved configuration values.
	load_configuration()

	# Listen for entered scenes so discovered areas can be tracked.
	SceneManager.scene_entered.connect( _on_scene_entered )

	# Enable debug slot / save / load input.
	set_process_input( true )
	pass


func _input(event: InputEvent) -> void:
	# Debug shortcuts for saving/loading and selecting slots.
	if OS.is_debug_build() and event is InputEventKey and event.pressed:
		if event.keycode == KEY_F5:
			save_game()
		elif event.keycode == KEY_F7:
			load_game()
		elif event.keycode == KEY_1:
			current_slot = 0
			print("Current slot: ", current_slot)
		elif event.keycode == KEY_2:
			current_slot = 1
			print("Current slot: ", current_slot)
		elif event.keycode == KEY_3:
			current_slot = 2
			print("Current slot: ", current_slot)
	pass


#region /// new game / save creation
func create_new_game_save(slot: int = 0) -> void:
	current_slot = slot

	discovered_areas.clear()
	persistent_data.clear()

	discovered_areas.append( DEFAULT_SCENE_PATH )

	save_data = {
		"scene_path": DEFAULT_SCENE_PATH,
		"x": 100.0,
		"y": -80.0,
		"hp": 20.0,
		"max_hp": 20.0,
		"dash": false,
		"double_jump": false,
		"lightning": false,
		"Chain_lightning": false,
		"dark_blast": false,
		"heavy_attack": false,
		"power_up": false,
		"ground_slam": false,
		"morph": false,
		"spell2": false,
		"spell3": false,
		"spell4": false,
		"spell5": false,
		"spell6": false,
		"spell7": false,
		"spell8": false,
		"discovered_areas": discovered_areas,
		"persistent_data": persistent_data,
	}

	write_to_save_file()
	load_game()

	print("Created new game save at: ", get_file_name())
	pass
#endregion


#region /// save / load game
func save_game() -> void:
	var player: Player = get_tree().get_first_node_in_group("Player")
	if player == null:
		print("No player found")
		return

	save_data = {
		"scene_path": SceneManager.current_scene_uid,
		"x": player.global_position.x,
		"y": player.global_position.y,
		"hp": player.hp,
		"max_hp": player.max_hp,
		"dash": player.dash,
		"double_jump": player.double_jump,
		"lightning": player.lightning,
		"Chain_lightning": player.Chain_lightning,
		"dark_blast": player.dark_blast,
		"heavy_attack": player.heavy_attack,
		"power_up": player.power_up,
		"ground_slam": player.ground_slam,
		"morph": player.morph,
		"spell2": player.spell2,
		"spell3": player.spell3,
		"spell4": player.spell4,
		"spell5": player.spell5,
		"spell6": player.spell6,
		"spell7": player.spell7,
		"spell8": player.spell8,
		"discovered_areas": discovered_areas,
		"persistent_data": persistent_data,
	}

	write_to_save_file()
	print("Game saved to: ", get_file_name())
	pass


func load_game() -> void:
	if not FileAccess.file_exists( get_file_name() ):
		print("No save file found at: ", get_file_name())
		return

	var save_file = FileAccess.open( get_file_name(), FileAccess.READ )
	save_data = JSON.parse_string( save_file.get_line() )

	persistent_data = save_data.get( "persistent_data", {} )
	discovered_areas = save_data.get( "discovered_areas", [] )

	var scene_path: String = save_data.get( "scene_path", DEFAULT_SCENE_PATH )

	SceneManager.transition_scene( scene_path, "", Vector2.ZERO, "up" )
	await SceneManager.new_scene_ready

	setup_player()
	pass


func setup_player() -> void:
	var player : Player = null

	while not player:
		player = get_tree().get_first_node_in_group( "Player" )
		await get_tree().process_frame

	player.max_hp = save_data.get( "max_hp", 20 )
	player.hp = save_data.get( "hp", 20 )

	player.dash = save_data.get( "dash", false )
	player.double_jump = save_data.get( "double_jump", false )
	player.lightning = save_data.get( "lightning", false )
	player.Chain_lightning = save_data.get( "Chain_lightning", false )
	player.dark_blast = save_data.get( "dark_blast", false )
	player.heavy_attack = save_data.get( "heavy_attack", false )
	player.power_up = save_data.get( "power_up", false )
	player.ground_slam = save_data.get( "ground_slam", false )
	player.morph = save_data.get( "morph", false )
	player.spell2 = save_data.get( "spell2", false )
	player.spell3 = save_data.get( "spell3", false )
	player.spell4 = save_data.get( "spell4", false )
	player.spell5 = save_data.get( "spell5", false )
	player.spell6 = save_data.get( "spell6", false )
	player.spell7 = save_data.get( "spell7", false )
	player.spell8 = save_data.get( "spell8", false )

	player.global_position = Vector2(
		save_data.get( "x", 0 ),
		save_data.get( "y", 0 )
	)

	print("Player restored at: ", player.global_position)
	pass
#endregion


#region /// file handling
func get_file_name() -> String:
	return "user://" + SLOTS[ current_slot ] + ".sav"


func write_to_save_file() -> void:
	var save_file = FileAccess.open( get_file_name(), FileAccess.WRITE )
	save_file.store_line( JSON.stringify( save_data ) )
	save_file.close()
	pass


func save_file_exists(slot: int) -> bool:
	return FileAccess.file_exists( "user://" + SLOTS[ slot ] + ".sav" )
#endregion


#region /// discovered areas tracking
func _on_scene_entered(scene_uid: String) -> void:
	if not discovered_areas.has( scene_uid ):
		discovered_areas.append( scene_uid )
	pass


func is_area_discovered(scene_uid: String) -> bool:
	return discovered_areas.has( scene_uid )
#endregion


#region /// configuration
func save_configuration() -> void:
	var config := ConfigFile.new()
	config.set_value( "audio", "music", AudioServer.get_bus_volume_linear( 2 ) )
	config.set_value( "audio", "sfx", AudioServer.get_bus_volume_linear( 3 ) )
	config.set_value( "audio", "ui", AudioServer.get_bus_volume_linear( 4 ) )
	config.save( CONFIG_FILE_PATH )
	pass


func load_configuration() -> void:
	var config := ConfigFile.new()
	var err = config.load( CONFIG_FILE_PATH )

	if err != OK:
		AudioServer.set_bus_volume_linear( 2, 0.8 )
		AudioServer.set_bus_volume_linear( 3, 1.0 )
		AudioServer.set_bus_volume_linear( 4, 1.0 )
		save_configuration()
		return

	AudioServer.set_bus_volume_linear( 2, config.get_value( "audio", "music", 0.8 ) )
	AudioServer.set_bus_volume_linear( 3, config.get_value( "audio", "sfx", 1.0 ) )
	AudioServer.set_bus_volume_linear( 4, config.get_value( "audio", "ui", 1.0 ) )
	pass
#endregion
