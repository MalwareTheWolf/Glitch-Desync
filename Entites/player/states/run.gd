@icon("uid://b044gwmkvmxmt")
class_name PlayerStateRun
extends PlayerState

func init() -> void:
	pass

func enter() -> void:
	if player.animation_player:
		player.animation_player.play("Run")

func exit() -> void:
	pass

func handle_input(event: InputEvent) -> PlayerState:
	if event.is_action_pressed("dash") and player.can_dash():
		return dash

	if event.is_action_pressed("attack"):
		return attack

	if event.is_action_pressed("jump"):
		return jump

	return null

func process(_delta: float) -> PlayerState:
	if not player.run:
		return walk

	if player.direction.x == 0.0:
		return idle

	if player.direction.y > 0.5:
		return crouch

	if not player.wants_to_run:
		return walk

	if not player.is_on_floor():
		return fall

	return null

func physics_process(_delta: float) -> PlayerState:
	if player.is_on_floor():
		player.velocity.x = player.direction.x * player.run_speed
	else:
		player.velocity.x = player.direction.x * player.air_velocity

	if not player.is_on_floor():
		return fall

	return null
