class_name PlayerStateFall extends PlayerState 


func init() -> void: 

	pass 


#what happens when entering the state 
func enter() -> void: 
	player.add_debug_indicator( Color.BLUE )
#play animation
	pass 


#what happens when exiting the state 
func exit() -> void: 
	pass 


#what happens when an input is pressed 
func handle_input( _event : InputEvent ) -> PlayerState: 
	#handle input
	return next_state 


#what happens each process tick in this state 
func process( _delta: float) -> PlayerState: 
	return next_state 


#what happens each process tick in this state 
func physics_process( _delta: float) -> PlayerState: 
	if player.is_on_floor():
		player.add_debug_indicator( Color.RED )
		return idle
	player.velocity.x = player.direction.x * player.air_velocity
	return next_state 

 
