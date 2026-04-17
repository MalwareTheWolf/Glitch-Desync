extends Node2D
class_name PreviewActor

@onready var sprite: Sprite2D = $Sprite2D
@onready var animation_player: AnimationPlayer = $AnimationPlayer


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

	if animation_player and animation_player.has_animation("idle"):
		animation_player.play("idle")


func play_anim(anim_name: String, speed: float = 1.0) -> void:
	if animation_player == null:
		return

	if animation_player.has_animation(anim_name):
		animation_player.stop()
		animation_player.speed_scale = speed
		animation_player.play(anim_name)
	else:
		print("PreviewActor: missing animation -> ", anim_name)
		print("Available:", animation_player.get_animation_list())


func face_right() -> void:
	if sprite:
		sprite.flip_h = false


func face_left() -> void:
	if sprite:
		sprite.flip_h = true


func reset_actor(pos: Vector2) -> void:
	position = pos
	face_right()
	play_anim("idle", 1.0)
