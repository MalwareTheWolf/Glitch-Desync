class_name PlayerStateJump extends PlayerState 

@export var jump_velocity : float = 450.0



func init() -> void: 

	pass 


#what happens when entering the state 
func enter() -> void: 
	#play animation
	player.add_debug_indicator( Color.WEB_GREEN )
	player.velocity.y -= jump_velocity
	pass 


#what happens when exiting the state 
func exit() -> void: 
	player.add_debug_indicator( Color.YELLOW )
	pass 


#what happens when an input is pressed 
func handle_input( event : InputEvent ) -> PlayerState: 
	if event.is_action_released( "jump" ):
		player.velocity.y *= 0.5
		return fall
	return next_state 


#what happens each process tick in this state 
func process( _delta: float) -> PlayerState: 
	if player.direction.y != 0:
		return idle
	return next_state 


#what happens each process tick in this state 
func physics_process( _delta: float) -> PlayerState: 
	if player.is_on_floor():
		return idle
	elif player.velocity.y >= 0:
		return fall
	player.velocity.x = player.direction.x * player.air_velocity
	return next_state 

 
