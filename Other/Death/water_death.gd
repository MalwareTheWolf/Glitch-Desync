extends Area2D

@export var drown_time: float = 3.0  # seconds before death

# Track which bodies are in the water
var bodies_in_water := {}

func _ready():
	connect("body_entered", Callable(self, "_on_body_entered"))
	connect("body_exited", Callable(self, "_on_body_exited"))

func _on_body_entered(body: Node) -> void:
	if body is Player:
		# Start a timer for this body
		var timer = Timer.new()
		timer.wait_time = drown_time
		timer.one_shot = true
		timer.autostart = true
		add_child(timer)
		
		# Correct way to pass the player to the timeout signal in Godot 4
		timer.timeout.connect(Callable(self, "_on_drown_timeout").bind(body))
		
		bodies_in_water[body] = timer

func _on_body_exited(body: Node) -> void:
	if body in bodies_in_water:
		# Player left water, cancel drowning
		bodies_in_water[body].queue_free()
		bodies_in_water.erase(body)

func _on_drown_timeout(player: Node) -> void:
	if player in bodies_in_water:
		player.die("drowning")
		bodies_in_water[player].queue_free()
		bodies_in_water.erase(player)
