class_name PlayerStateDash
extends PlayerState

# Dash state.
# Handles fast horizontal movement, invulnerability, and visual effects.


#CONSTANTS

const DASH_AUDIO = preload("uid://fp3pia3qydwj")


#TUNABLES

@export var duration : float = 0.25
# Total dash duration.

@export var speed : float = 300.0
# Base dash speed.

@export var effect_delay : float = 0.05
# Time between ghost effects.


#RUNTIME

var dir : float = 1.0
# Direction of dash.

var time : float = 0.0
# Remaining dash time.

var effect_time : float = 0.0
# Timer for ghost effect.


#NODE REFERENCES

@onready var damageable_area: DamageableArea = %DamageableArea
# Reference to damageable area for invulnerability.


#LIFECYCLE

# What happens when this state is initialized?
func init() -> void:
	pass


# What happens when we enter this state?
func enter() -> void:

	# Play dash animation.
	if player.animation_player:
		player.animation_player.play("Dash")

	time = duration
	effect_time = 0.0

	# Determine dash direction.
	get_dash_direction()

	# Grant temporary invulnerability.
	damageable_area.make_invulnerable(duration)

	# Play dash sound.
	Audio.play_spatial_sound(DASH_AUDIO, player.global_position)

	# Disable gravity during dash.
	player.gravity_multiplier = 0.0
	player.velocity.y = 0

	# Consume dash.
	player.dash_count += 1

	# Visual flash effect (FIXED: replaces broken tween_color).
	var tween: Tween = create_tween()
	tween.tween_property(player.sprite, "modulate", Color(1,1,1,0.5), duration * 0.5)
	tween.tween_property(player.sprite, "modulate", Color(1,1,1,1), duration * 0.5)


# What happens when we exit this state?
func exit() -> void:

	# Restore gravity.
	player.gravity_multiplier = 1.0


#INPUT

# What happens when an input is pressed?
func handle_input(_event : InputEvent) -> PlayerState:

	# Allow morph during dash (if enabled).
	if _event.is_action_pressed("action") and player.can_morph():
		return ball

	return null


#PROCESS

# What happens each process tick in this state?
func process(_delta: float) -> PlayerState:

	time -= _delta

	# End dash when time runs out.
	if time <= 0:

		if player.is_on_floor():
			return idle
		else:
			return fall

	# Handle ghost trail effect.
	effect_time -= _delta

	if effect_time < 0:
		effect_time = effect_delay
		player.sprite.ghost()

	return null


#PHYSICS

# What happens each physics_process tick in this state?
func physics_process(_delta: float) -> PlayerState:

	# Apply dash velocity (slight decay over time).
	player.velocity.x = (speed * (time / duration) + speed) * dir

	return null


#HELPERS

# Determines dash direction based on input/sprite.
func get_dash_direction() -> void:

	# Prefer input direction.
	dir = sign(player.direction.x)

	# Fallback to sprite facing.
	if dir == 0:
		dir = -1.0 if player.sprite.flip_h else 1.0
