extends Control

# Debug menu controller.
# Handles toggles, cheats, and live debugging info.


#NODE REFERENCES
@onready var debug_label: Label = $Label

# Displays live debug information.

@onready var infinite_health_button: BaseButton = $VBoxContainer/Infinite_Health
@onready var unlock_ability_button: BaseButton = $VBoxContainer/Unlock_Ability
@onready var particles_button: BaseButton = $VBoxContainer/Particles
@onready var kill_player_button: BaseButton = $VBoxContainer/GameOver


#RUNTIME

var player: Player
# Reference to player.

var infinite_health: bool = false
# Toggle for infinite health.



#LIFECYCLE

func _ready() -> void:

	# Get player reference.
	player = get_tree().get_first_node_in_group("Player")

	# Connect buttons.
	if infinite_health_button:
		infinite_health_button.pressed.connect(_on_infinite_health_pressed)

	if unlock_ability_button:
		unlock_ability_button.pressed.connect(_on_unlock_ability_pressed)

	if particles_button:
		particles_button.pressed.connect(_on_particles_pressed)

	if kill_player_button:
		kill_player_button.pressed.connect(_on_kill_player_pressed)

	# Start hidden.
	visible = false

#PROCESS

func _process(_delta: float) -> void:

	if player == null:
		player = get_tree().get_first_node_in_group("Player")
		return

	# Infinite health enforcement.
	if infinite_health:
		player.hp = player.max_hp

	# Update debug label.
	_update_debug_label()



#DEBUG DISPLAY

# Updates on-screen debug information.
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
""" % [
		player.current_state.name,
		player.hp,
		player.max_hp,
		player.dash,
		player.dash_count,
		player.can_dash(),
		player.is_on_floor(),
		player.velocity
	]



#DEBUG ACTIONS

# Toggles infinite health.
func _on_infinite_health_pressed() -> void:

	infinite_health = !infinite_health

	print("Infinite Health:", infinite_health)



# Unlocks a ability.
func _on_unlock_ability_pressed() -> void:

	if player == null:
		return

	player.morph = true

	print("Dash unlocked")



# Spawns test particle effects.
func _on_particles_pressed() -> void:

	if player == null:
		return

	VisualEffects.jump_dust(player.global_position)
	VisualEffects.land_dust(player.global_position)
	VisualEffects.hit_dust(player.global_position)

	print("Spawned test particles")



# Forces player death.
func _on_kill_player_pressed() -> void:

	if player == null:
		return

	player.hp = 0

	if player.death:
		player.change_state(player.death)

	print("Player killed (debug)")
