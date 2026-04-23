@icon("uid://b044gwmkvmxmt")
class_name PlayerStateCast
extends PlayerState

# Shared spell cast state.
# Cast animation is the laser ability while right mouse is held.


#TUNABLES

@export var cast_move_speed: float = 0.0
# Movement speed while casting.



#LIFECYCLE

func init() -> void:
	pass


func enter() -> void:
	player.cast_finished = false

	if player.animation_player:
		player.animation_player.play("Cast")

	if player.laser:
		player.laser.player = player
		player.laser.facing_sign = -1.0 if player.sprite.flip_h else 1.0
		player.laser.is_casting = true
		player.laser.is_channeling = true


func exit() -> void:
	if player.laser:
		player.laser.is_casting = false
		player.laser.is_channeling = false



#INPUT

func handle_input(_event: InputEvent) -> PlayerState:
	# Player is locked in place while casting.
	return null



#PROCESS

func process(_delta: float) -> PlayerState:
	# Falling always overrides.
	if not player.is_on_floor():
		return fall

	var cast_held := Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT)

	# Release exits cast immediately.
	if not cast_held:
		if player.direction.x != 0:
			return walk
		else:
			return idle

	return null



#PHYSICS

func physics_process(_delta: float) -> PlayerState:
	# Lock horizontal movement while casting.
	player.velocity.x = cast_move_speed

	return null
