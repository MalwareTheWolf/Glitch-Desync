##controls the water body
##conatins all the springs needed for water effect
extends Node2D

#Springiness, dampening, and spread of springs
#spread will decide how far apart springs are
@export var k = 0.015
@export var d = 0.03
@export var spread = 0.015

#spring array
var springs = []

#initialize the spring array and all springs
func _ready():
	for i in get_children():
		springs.append(i)
		i.initialize()
	
	splash(2,5)
	
func _physics_process( _delta ):

	for i in springs:
		i.water_update(k,d)
	
	var left_deltas = []
	var right_deltas = []
	
	for i in range (springs.size()):
		left_deltas.append(0)
		right_deltas.append(0)
		pass
	
	for i in range (springs.size()):
		if i > 0:
			left_deltas[i] = spread * (springs[i].height - springs[i-1].height)
			springs[i-1].velocity += left_deltas[i]
		if i < springs.size()-1:
			right_deltas[i] = spread * (springs[i].height - springs[i+1].height)
			springs[i+1].velocity += right_deltas[i]

func splash(index, speed):
	if index >= 0 and index < springs.size():
		springs[index].velocity += speed
	
	pass
