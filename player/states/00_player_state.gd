@icon("res://player/states/state.svg")
class_name PlayerState extends Node

var player : Player
var next_state : PlayerState

#region /// state references
#reference to all other states
@onready var run: PlayerStateRun = %Run
@onready var idle: PlayerStateIdle = %Idle
#endregion


#what happens when the state is initialized
func init() -> void:
	pass


#what happens when entering the state
func enter() -> void:
	pass


#what happens when exiting the state
func exit() -> void:
	pass


#what happens when an input is pressed
func handle_input( _event : InputEvent ) -> PlayerState:
	return next_state


#what happens each process tick in this state
func process( _delta: float) -> PlayerState:
	return next_state


#what happens each process tick in this state
func physics_process( _delta: float) -> PlayerState:
	return next_state
