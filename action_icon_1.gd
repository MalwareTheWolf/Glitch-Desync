extends Control

@onready var unpressed_icon: TextureRect = $UnpressedIcon
@onready var pressed_icon: TextureRect = $PressedIcon
@onready var anim: AnimationPlayer = $AnimationPlayer

func set_button(action_name: String, mode: int) -> void:
	var unpressed_tex := InputIconLibrary.get_unpressed_icon(action_name)
	var pressed_tex := InputIconLibrary.get_pressed_icon(action_name)

	unpressed_icon.texture = unpressed_tex
	pressed_icon.texture = pressed_tex

	_fit_icon_size(unpressed_tex)

	match mode:
		0:
			anim.play("idle")
		1:
			anim.play("tap")
		2:
			anim.play("hold")

func _fit_icon_size(tex: Texture2D) -> void:
	if tex == null:
		return

	var icon_size := tex.get_size()

	custom_minimum_size = icon_size
	size = icon_size

	unpressed_icon.position = Vector2.ZERO
	pressed_icon.position = Vector2.ZERO

	unpressed_icon.custom_minimum_size = icon_size
	pressed_icon.custom_minimum_size = icon_size

	unpressed_icon.size = icon_size
	pressed_icon.size = icon_size

	unpressed_icon.stretch_mode = TextureRect.STRETCH_KEEP
	pressed_icon.stretch_mode = TextureRect.STRETCH_KEEP
