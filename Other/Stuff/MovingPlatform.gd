extends PathFollow2D

@export var move_speed: float = 0.3
@export var rotate_duration: float = 0.25
@export var rotate_angle: float = 90.0

var direction: int = 1
var rotating: bool = false
var wrapper: Node2D

func _ready():
	wrapper = $PlatformWrapper
	if not wrapper:
		print("ERROR: PlatformWrapper not found!")

func _process(delta):
	if rotating:
		return
	
	progress_ratio += move_speed * direction * delta
	
	# Reverse direction at path ends
	if progress_ratio >= 1.0:
		progress_ratio = 1.0
		direction = -1
		rotate_platform()
	elif progress_ratio <= 0.0:
		progress_ratio = 0.0
		direction = 1
		rotate_platform()

func rotate_platform():
	if not wrapper:
		return
	rotating = true
	var tween = create_tween()
	tween.tween_property(wrapper, "rotation", wrapper.rotation + deg_to_rad(rotate_angle), rotate_duration)
	tween.finished.connect(_on_rotation_finished)

func _on_rotation_finished():
	rotating = false
