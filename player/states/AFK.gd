@icon("uid://b044gwmkvmxmt")
class_name PlayerStateAFK
extends PlayerState

func init() -> void:
	pass

func enter() -> void:
	if not player:
		return

	player.last_input_time = 0.0

	if player.animation_player:
		player.animation_player.play("AFK")

func exit() -> void:
	if not player:
		return

	player.last_input_time = 0.0

	if player.animation_player:
		player.animation_player.play("Idle")

func handle_input(event: InputEvent) -> PlayerState:
	if not player:
		return null

	if not event.is_pressed():
		return null

	if event.is_action_pressed("dash") and player.can_dash():
		return dash

	if event.is_action_pressed("attack"):
		return attack

	if event.is_action_pressed("jump"):
		return jump

	if event.is_action_pressed("Cast"):
		return cast

	if event.is_action_pressed("action") and player.can_morph():
		return ball

	if Input.get_axis("left", "right") != 0.0:
		if player.run and player.wants_to_run:
			return run
		return walk

	if Input.get_axis("up", "down") > 0.5:
		return crouch

	return idle

func process(_delta: float) -> PlayerState:
	if not player:
		return null

	if not player.is_on_floor():
		return fall

	return null

func physics_process(_delta: float) -> PlayerState:
	if not player:
		return null

	if player.is_on_floor():
		player.velocity.x = 0.0
	else:
		player.velocity.x = player.direction.x * player.air_velocity

	if not player.is_on_floor():
		return fall

	return null
