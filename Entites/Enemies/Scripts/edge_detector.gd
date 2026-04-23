@icon("uid://5qtwbaq30oot")
class_name EdgeDetector
extends RayCast2D

signal edge_detected

func _ready() -> void:
	set_collision_mask_value(1, true)
	set_collision_mask_value(2, true)

func _physics_process(_delta: float) -> void:
	var is_colliding: bool = is_colliding()

	if not is_colliding:
		edge_detected.emit()
