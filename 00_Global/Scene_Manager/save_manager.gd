extends Node
# SaveManager script.
# Handles creating save files, writing save data, loading save data,
# and restoring the player after scene transitions.



const SLOTS: Array[String] = [
	"save_01",
	"save_02",
	"save_03"
]
# Save slot file names.


var current_slot: int = 0
var save_data: Dictionary
var discovered_areas: Array = []
var persistent_data: Dictionary = {}



func _ready() -> void:
	pass


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_F5:
			print("F5 pressed")
			save_game()
		elif event.keycode == KEY_F7:
			print("F7 pressed")
			load_game()
	pass


func create_new_game_save() -> void:
	var new_game_scene: String = "res://World/00_Void/01.tscn"

	discovered_areas = [ new_game_scene ]
	persistent_data = {}

	save_data = {
		"scene_path": new_game_scene,
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

	var save_file = FileAccess.open(get_file_name(), FileAccess.WRITE)
	save_file.store_line(JSON.stringify(save_data))
	print("Created new save at: ", get_file_name())
	pass


func save_game() -> void:
	print("save_game()")

	var player: Player = get_tree().get_first_node_in_group("Player")

	if player == null:
		print("No player found")
		return

	print("We have a player")
	print("Saving to: ", get_file_name())

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

	var save_file = FileAccess.open(get_file_name(), FileAccess.WRITE)

	if save_file == null:
		print("Failed to open save file")
		return

	save_file.store_line(JSON.stringify(save_data))
	print("Saved successfully")
	pass


func load_game() -> void:
	print("load_game()")

	if not FileAccess.file_exists(get_file_name()):
		print("No save file found at: ", get_file_name())
		return

	var save_file = FileAccess.open(get_file_name(), FileAccess.READ)
	save_data = JSON.parse_string(save_file.get_line())

	persistent_data = save_data.get("persistent_data", {})
	discovered_areas = save_data.get("discovered_areas", [])

	var scene_path: String = save_data.get("scene_path", "res://World/00_Void/01.tscn")
	print("Loading scene path: ", scene_path)

	SceneManager.transition_scene(scene_path, "", Vector2.ZERO, "up")
	await SceneManager.new_scene_ready
	setup_player()

	pass


func setup_player() -> void:
	var player: Player = null

	while not player:
		player = get_tree().get_first_node_in_group("Player")
		await get_tree().process_frame

	player.max_hp = save_data.get("max_hp", 20)
	player.hp = save_data.get("hp", 20)

	player.dash = save_data.get("dash", false)
	player.double_jump = save_data.get("double_jump", false)
	player.lightning = save_data.get("lightning", false)
	player.Chain_lightning = save_data.get("Chain_lightning", false)
	player.dark_blast = save_data.get("dark_blast", false)
	player.heavy_attack = save_data.get("heavy_attack", false)
	player.power_up = save_data.get("power_up", false)
	player.ground_slam = save_data.get("ground_slam", false)
	player.morph = save_data.get("morph", false)
	player.spell2 = save_data.get("spell2", false)
	player.spell3 = save_data.get("spell3", false)
	player.spell4 = save_data.get("spell4", false)
	player.spell5 = save_data.get("spell5", false)
	player.spell6 = save_data.get("spell6", false)
	player.spell7 = save_data.get("spell7", false)
	player.spell8 = save_data.get("spell8", false)

	player.global_position = Vector2(
		save_data.get("x", 0),
		save_data.get("y", 0)
	)

	print("Player restored at: ", player.global_position)
	pass


func get_file_name() -> String:
	return "user://" + SLOTS[current_slot] + ".sav"
