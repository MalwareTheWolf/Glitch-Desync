extends PlayerState
class_name PlayerStateJump

@export var jump_velocity: float = 450.0

func init() -> void:
	pass

func enter() -> void:
	player.animation_player.play("Jump")
	player.animation_player.pause()
	#player.add_debug_indicator(Color.WEB_GREEN)
	player.velocity.y = -jump_velocity

func exit() -> void:
	#player.add_debug_indicator(Color.YELLOW)
	pass

func handle_input(event: InputEvent) -> PlayerState:
	if event.is_action_released("jump"):
		player.velocity.y *= 0.5
		return fall
	return next_state

func process(_delta: float) -> PlayerState:
	set_jump_frame()
	return next_state

func physics_process(_delta: float) -> PlayerState:
	if player.is_on_floor():
		return idle
	elif player.velocity.y >= 0:
		return fall

	player.velocity.x = player.direction.x * player.air_velocity
	return next_state

func set_jump_frame() -> void:
	var frame: float = remap( player.velocity.y, -jump_velocity, 0.0, 0.0, 0.5 )
	player.animation_player.seek(frame, true)
	pass
