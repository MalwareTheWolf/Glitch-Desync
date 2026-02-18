#Water Effects by making "spings" to get the effects

extends Node2D

#"Spring" Current Velocity
var velocity = 0

#the force applied to te spring
var force = 0

#the current height of the spring
var height = 0

#the natural position of the spring
var target_height = 0

func water_update(spring_constant, dampening):
	##this applies hooke's law force to the spring
	##this function will be called each frame
	## hookes law | F= - K * x
	
	#update height value based on your current position
	height = position.y
	
	#springs current extension
	var x = height - target_height
	
	var loss = -dampening * velocity
	
	#hookes law
	force = - spring_constant * x + loss
	
	#apply force to the velocity
	#equivelent to velocity = velocity + force
	velocity += force
	
	#make spring move
	position.y += velocity
	pass

func initialize():
	height = position.y
	target_height = position.y
	velocity = 0
