##controls the water body
##conatins all the springs needed for water effect
extends Node2D

#Springiness, dampening, and spread of springs
#spread will decide how far apart springs are
@export var k = 0.015
@export var d = 0.03
@export var spread = 0.0002

#spring array
var springs = []
var passes = 8

#distance between each spring
@export var distance_between_springs = 32
#how many springs
@export var spring_number = 6

#total water body length
var water_length = distance_between_springs * spring_number

@onready var water_spring = preload("res://Water Scenes/Water_Spring.tscn")

#body of water depth
@export var depth = 1000
var target_height = global_position.y
var bottom = target_height + depth

@onready var water_polygon: Polygon2D = %Water_Polygon


#initialize the spring array and all springs
func _ready():
	
	#loops through all springs
	#makes and array with all springs
	#initializes each spring
	for i in range(spring_number):
		#the spring in the x position
		#generated from left to right 0, 32, 64, 96,...
		var x_position = distance_between_springs * i
		var w = water_spring.instantiate()
		
		add_child(w)
		springs.append(w)
		w.initialize(x_position)
	
	splash(10,4)
	
func _physics_process( _delta ):

	for i in springs:
		i.water_update(k,d)
	
	var left_deltas = []
	var right_deltas = []
	
	for i in range (springs.size()):
		left_deltas.append(0)
		right_deltas.append(0)
		pass
	
	for j in range(passes):
		#loop through each spring
		for i in range (springs.size()):
		#adds velocity to the left of the current spring
			if i > 0:
				left_deltas[i] = spread * (springs[i].height - springs[i-1].height)
				springs[i-1].velocity += left_deltas[i]
		#adds velocity to the left of the current spring
			if i < springs.size()-1:
				right_deltas[i] = spread * (springs[i].height - springs[i+1].height)
				springs[i+1].velocity += right_deltas[i]
	draw_water_body()
	
func draw_water_body():
	#will hold position of points
	var surface_points = []
	
	#makes a new array with position of points
	for i in range(springs.size()):
		surface_points.append(springs[i].position)
	
	#gets first and last index for surface array
	var first_index = 0
	var last_index = surface_points.size()-1
	
	#the water polygon will contain all the points of the surface
	var water_polygon_points = surface_points
	
	#add pther two points at the bottom of the polygon, to close the water body
	water_polygon_points.append(Vector2(surface_points[last_index].x, bottom))
	water_polygon_points.append(Vector2(surface_points[first_index].x, bottom))
	
	#transform normal array into packedvector2array
	#the polygon draw function uses packedvectr2arrays to draw the polygon, s we converted it
	water_polygon_points = PackedVector2Array(water_polygon_points)
	
	water_polygon.set_polygon(water_polygon_points)
	
func splash(index, speed):
	if index >= 0 and index < springs.size():
		springs[index].velocity += speed
	
	pass
