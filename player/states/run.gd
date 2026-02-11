class_name PlayerStateRun extends PlayerState 


func init() -> void: 

	pass 


#what happens when entering the state 
func enter() -> void: 
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
	if player.direction.x == 0:
		return idle
	return next_state 


#what happens each process tick in this state 
func physics_process( _delta: float) -> PlayerState: 
	player.velocity.x = player.direction.x * player.move_speed
	return next_state 

 
