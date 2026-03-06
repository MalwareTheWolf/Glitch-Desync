@icon("res://General/Icon/save_point.svg")
class_name SavePoint
extends Node2D

@export var save_lock_time : float = 1.5
# How long the player stays locked when using this save point.

@onready var area_2d: Area2D = $Area2D
@onready var animation_player: AnimationPlayer = $Node2D/AnimationPlayer


func _ready() -> void:
	area_2d.body_entered.connect(_on_player_entered)
	area_2d.body_exited.connect(_on_player_exited)
	pass


func _on_player_entered(_n: Node2D) -> void:
	# Connect interaction signal and show input hint
	Messages.player_interacted.connect(_on_player_interacted)
	Messages.input_hint_changed.emit("interact")
	pass


func _on_player_exited(_n: Node2D) -> void:
	# Disconnect interaction signal and hide input hint
	if Messages.player_interacted.is_connected(_on_player_interacted):
		Messages.player_interacted.disconnect(_on_player_interacted)
	Messages.input_hint_changed.emit("")
	pass


func _on_player_interacted(player: Player) -> void:
	# Lock player movement for a set time
	player.lock_movement_with_timer(save_lock_time)

	# Play player save animation
	player.animation_player.play("Save")

	# Play save point animation
	animation_player.play("game_saved")
	animation_player.seek(0)

	# Heal player and emit event
	player.hp = player.max_hp
	Messages.player_healed.emit(999)

	# Save game
	SaveManager.save_game()

	# Play UI/audio feedback

	pass
