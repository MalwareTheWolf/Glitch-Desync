# Spike.gd
extends Area2D

func _ready():
	# Connect the body_entered signal to this script
	connect("body_entered", Callable(self, "_on_body_entered"))

func _on_body_entered(body: Node) -> void:
	# Check if the player touched the spikes
	if body is Player:
		body.die("spikes")
