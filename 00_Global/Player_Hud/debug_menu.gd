extends Control

@onready var debug_label: Label = $Label
@onready var infinite_health_button: BaseButton = $VBoxContainer/Infinite_Health
@onready var unlock_ability_button: BaseButton = $VBoxContainer/Unlock_Ability
@onready var particles_button: BaseButton = $VBoxContainer/Particles
@onready var kill_player_button: BaseButton = $VBoxContainer/GameOver

var player: Player
var infinite_health: bool = false

var ability_list: Array[String] = [
	"run",
	"dash",
	"double_jump",
	"lightning",
	"Chain_lightning",
	"dark_blast",
	"heavy_attack",
	"power_up",
	"ground_slam",
	"morph"
]

var current_ability_index: int = 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

	player = get_tree().get_first_node_in_group("Player")

	if infinite_health_button:
		infinite_health_button.pressed.connect(_on_infinite_health_pressed)

	if unlock_ability_button:
		unlock_ability_button.pressed.connect(_on_unlock_ability_pressed)

	if particles_button:
		particles_button.pressed.connect(_on_particles_pressed)

	if kill_player_button:
		kill_player_button.pressed.connect(_on_kill_player_pressed)

	update_unlock_ability_button()
	visible = false


func _process(_delta: float) -> void:
	if player == null:
		player = get_tree().get_first_node_in_group("Player")
		update_unlock_ability_button()
		return

	if infinite_health:
		player.hp = player.max_hp

	_update_debug_label()


func _input(event: InputEvent) -> void:
	if not visible:
		return

	if event is InputEventKey and not event.pressed:
		return

	if event.is_action_pressed("ui_right") or _is_physical_key_pressed(event, KEY_RIGHT):
		next_ability()
		get_viewport().set_input_as_handled()
		return

	if event.is_action_pressed("ui_left") or _is_physical_key_pressed(event, KEY_LEFT):
		previous_ability()
		get_viewport().set_input_as_handled()
		return


func _is_physical_key_pressed(event: InputEvent, keycode: Key) -> bool:
	if event is InputEventKey:
		var key_event := event as InputEventKey
		return key_event.pressed and key_event.physical_keycode == keycode
	return false


func _update_debug_label() -> void:
	if not debug_label or player == null:
		return

	debug_label.text = """
STATE: %s
HP: %.1f / %.1f
DASH: %s
DASH COUNT: %d
CAN DASH: %s
ON FLOOR: %s
VELOCITY: %s
ABILITY: %s
""" % [
		player.current_state.name,
		player.hp,
		player.max_hp,
		player.dash,
		player.dash_count,
		player.can_dash(),
		player.is_on_floor(),
		player.velocity,
		format_ability_name(ability_list[current_ability_index])
	]


func update_unlock_ability_button() -> void:
	if unlock_ability_button == null:
		return

	if player == null:
		unlock_ability_button.text = "Unlock Ability"
		return

	var ability_name: String = ability_list[current_ability_index]
	var display_name: String = format_ability_name(ability_name)

	if player.get(ability_name):
		unlock_ability_button.text = display_name + " (Unlocked)"
	else:
		unlock_ability_button.text = "Unlock " + display_name


func next_ability() -> void:
	current_ability_index = (current_ability_index + 1) % ability_list.size()
	update_unlock_ability_button()


func previous_ability() -> void:
	current_ability_index = (current_ability_index - 1 + ability_list.size()) % ability_list.size()
	update_unlock_ability_button()


func format_ability_name(ability_name: String) -> String:
	var parts: PackedStringArray = ability_name.split("_")
	for i: int in range(parts.size()):
		parts[i] = parts[i].capitalize()
	return " ".join(parts)


func _on_infinite_health_pressed() -> void:
	infinite_health = !infinite_health


func _on_unlock_ability_pressed() -> void:
	if player == null:
		return

	var ability_name: String = ability_list[current_ability_index]
	player.set(ability_name, true)

	update_unlock_ability_button()


func _on_particles_pressed() -> void:
	if player == null:
		return

	VisualEffects.jump_dust(player.global_position)
	VisualEffects.land_dust(player.global_position)
	VisualEffects.hit_dust(player.global_position)


func _on_kill_player_pressed() -> void:
	if player == null:
		return

	player.hp = 0

	if player.death:
		player.change_state(player.death)
