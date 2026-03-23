class_name PlayerStateRun extends PlayerState

# What happens when this state is initialized?
func init() -> void:
	pass


# What happens when we enter this state?
func enter() -> void:

	if player.animation_player:
		player.animation_player.play("Run")
		# Plays run animation.


# What happens when we exit this state?
func exit() -> void:
	pass


# What happens when an input is pressed?
func handle_input(_event : InputEvent) -> PlayerState:

	# Dash input.
	if _event.is_action_pressed("dash") and player.can_dash():
		return dash

	# Attack input.
	if _event.is_action_pressed("attack"):
		return attack

	# Jump input.
	if _event.is_action_pressed("jump"):
		return jump

	# Morph input (disabled).
	# if _event.is_action_pressed("action") and player.can_morph():
	# 	return ball

	return null


# What happens each process tick in this state?
func process(_delta: float) -> PlayerState:

	# Stop running if no horizontal input.
	if player.direction.x == 0:
		return idle

	# Enter crouch if holding down.
	elif player.direction.y > 0.5:
		return crouch

	return null


# What happens each physics_process tick in this state?
func physics_process(_delta: float) -> PlayerState:

	if player.is_on_floor():

		# Ground movement.
		player.velocity.x = player.direction.x * player.move_speed

	else:

		# Air movement.
		player.velocity.x = player.direction.x * player.air_velocity

	# Transition to fall if not grounded.
	if not player.is_on_floor():
		return fall

	return null
