class_name PlayerStateBall
extends PlayerState

const MORPH_AUDIO = preload("uid://btsc86lmk1nis")
const MORPH_OUT_AUDIO = preload("uid://dhsq6lqs775q5")

@export var jump_velocity : float = 400

var on_floor : bool = true
var morph_locked : bool = false  # true during Morph_In or Morph_Out

@onready var ball_ray_up: RayCast2D = %BallRayUp
@onready var ball_ray_down: RayCast2D = %BallRayDown
@onready var jump_audio: AudioStreamPlayer2D = %JumpAudio
@onready var land_audio: AudioStreamPlayer2D = %LandAudio


# --- ENTER STATE ---
func enter() -> void:
	if not player:
		return

	# Start morph in animation
	morph_locked = true
	player.animation_player.play("Morph_In")

	# Adjust collision shape
	_set_ball_collision()

	# Give slight upward boost
	player.velocity.y -= 100

	# Play sound
	Audio.play_spatial_sound(MORPH_AUDIO, player.global_position)

	# Make player temporarily invulnerable
	if player.da_stand:
		player.da_stand.make_invulnerable(player.animation_player.current_animation_length)


# --- EXIT STATE ---
func exit() -> void:
	if not player:
		return

	# Restore collision shape to standing
	_set_stand_collision()

	player.velocity.y -= 100

	# Play morph out sound
	Audio.play_spatial_sound(MORPH_OUT_AUDIO, player.global_position)

	morph_locked = false


# --- HANDLE INPUT ---
func handle_input(event: InputEvent) -> PlayerState:
	if morph_locked:
		# Cannot move or unmorph during Morph_In/Out
		return null

	if event.is_action_pressed("action"):
		if _can_stand():
			return idle if player.is_on_floor() else fall

	if event.is_action_pressed("jump"):
		if player.is_on_floor():
			if Input.is_action_pressed("down") and player.one_way_shape_cast:
				player.one_way_shape_cast.force_shapecast_update()
				if player.one_way_shape_cast.is_colliding():
					player.position.y += 4
					return null

			player.velocity.y -= jump_velocity
			jump_audio.play()
			VisualEffects.jump_dust(player.global_position)

	return null


# --- PROCESS ---
func process(_delta: float) -> PlayerState:
	if morph_locked:
		player.animation_player.speed_scale = 0
	else:
		# Morph_Walk animation plays when moving
		player.animation_player.play("Morph_Walk")
		player.animation_player.speed_scale = 1 if player.direction.x != 0 else 0

	return null


# --- PHYSICS PROCESS ---
func physics_process(_delta: float) -> PlayerState:
	if not morph_locked:
		player.velocity.x = player.direction.x * player.move_speed

	# Handle landing dust
	if on_floor:
		if not player.is_on_floor():
			on_floor = false
	else:
		if player.is_on_floor():
			on_floor = true
			VisualEffects.land_dust(player.global_position)
			land_audio.play()

	return null


# --- COLLISION HELPERS ---
func _set_ball_collision() -> void:
	var shape := player.collision_stand.shape as CapsuleShape2D
	if shape:
		shape.radius = 11.0
		shape.height = 22.0
	player.collision_stand.position.y = -11
	if player.da_stand:
		player.da_stand.position.y = -11


func _set_stand_collision() -> void:
	var shape := player.collision_stand.shape as CapsuleShape2D
	if shape:
		shape.radius = 8.0
		shape.height = 46.0
	player.collision_stand.position.y = -23
	if player.da_stand:
		player.da_stand.position.y = -23


# --- CHECK IF CAN UNMORPH ---
func _can_stand() -> bool:
	ball_ray_up.force_raycast_update()
	ball_ray_down.force_raycast_update()
	return not (ball_ray_up.is_colliding() or ball_ray_down.is_colliding())
