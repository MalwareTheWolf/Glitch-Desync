class_name AbilityPickup
extends Node2D

enum AbilityId {
	RUN,
	DASH,
	DOUBLE_JUMP,
	LIGHTNING,
	CHAIN_LIGHTNING,
	DARK_BLAST,
	HEAVY_ATTACK,
	POWER_UP,
	GROUND_SLAM,
	MORPH
}

@export var ability_1: AbilityId = AbilityId.DASH
@export var ability_2_enabled: bool = false
@export var ability_2: AbilityId = AbilityId.DOUBLE_JUMP

@onready var breakable: Breakable = $Breakable
@onready var crystal: Node2D = $AbilityCrystal

var collected: bool = false


func _ready() -> void:
	if breakable:
		breakable.destroyed.connect(_on_breakable_destroyed)


func _on_breakable_destroyed() -> void:
	if collected:
		return

	collected = true

	var player: Player = get_tree().get_first_node_in_group("Player")
	if player == null:
		print("AbilityPickup: no player found")
		return

	_unlock_ability(player, ability_1)

	if ability_2_enabled:
		_unlock_ability(player, ability_2)

	var hud = get_tree().get_first_node_in_group("PlayerHud")
	if hud and hud.has_method("refresh_ability_icons"):
		hud.refresh_ability_icons()

	if crystal:
		crystal.visible = false

	queue_free()


func _unlock_ability(player: Player, ability: AbilityId) -> void:
	match ability:
		AbilityId.RUN:
			player.run = true
		AbilityId.DASH:
			player.dash = true
		AbilityId.DOUBLE_JUMP:
			player.double_jump = true
		AbilityId.LIGHTNING:
			player.lightning = true
		AbilityId.CHAIN_LIGHTNING:
			player.Chain_lightning = true
		AbilityId.DARK_BLAST:
			player.dark_blast = true
		AbilityId.HEAVY_ATTACK:
			player.heavy_attack = true
		AbilityId.POWER_UP:
			player.power_up = true
		AbilityId.GROUND_SLAM:
			player.ground_slam = true
		AbilityId.MORPH:
			player.morph = true
