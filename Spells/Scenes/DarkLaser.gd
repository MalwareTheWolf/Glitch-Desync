## Casts a laser along a raycast, emitting particles on the impact point.
## Use `is_casting` to make the laser fire and stop.
## The laser follows the mouse but is limited to a forward cone based on player facing.
@tool
class_name DarkLaser
extends RayCast2D

## Speed at which the laser extends when first fired, in pixels per seconds.
@export var cast_speed: float = 7000.0
## Maximum length of the laser in pixels.
@export var max_length: float = 1400.0
## Distance in pixels from the origin to start drawing and firing the laser.
@export var start_distance: float = 40.0
## Base duration of the tween animation in seconds.
@export var growth_time: float = 0.1
## Beam thickness used by the attached attack area.
@export var hitbox_height: float = 14.0
## Maximum cone angle in front of the player.
@export var cone_angle_degrees: float = 80.0
## Beam color.
@export var color: Color = Color.WHITE: set = set_color

## If `true`, the laser is firing.
## It plays appearing and disappearing animations when it's not animating.
@export var is_casting: bool = false: set = set_is_casting

## If `true`, the laser is in sustained cast mode.
@export var is_channeling: bool = false

var tween: Tween = null
var player: CharacterBody2D = null
# Player using the beam.
# Player using the beam.
var facing_sign: float = 1.0
# 1 = right, -1 = left.

@onready var line_2d: Line2D = %Line2D
@onready var casting_particles: GPUParticles2D = %CastingParticles2D
@onready var collision_particles: GPUParticles2D = %CollisionParticles2D
@onready var beam_particles: GPUParticles2D = %BeamParticles2D
@onready var attack_area: AttackArea = $AttackArea
@onready var attack_area_shape: CollisionShape2D = $AttackArea/CollisionShape2D

@onready var line_width: float = line_2d.width


func _ready() -> void:
	set_color(color)
	line_2d.points[0] = Vector2.RIGHT * start_distance
	line_2d.points[1] = Vector2.RIGHT * start_distance
	line_2d.visible = false
	casting_particles.position = line_2d.points[0]

	if attack_area:
		attack_area.set_active(false)
		attack_area.attack_area_hit.connect(_on_attack_area_hit)

	set_is_casting(is_casting)

	if not Engine.is_editor_hint():
		set_physics_process(false)


func _physics_process(delta: float) -> void:
	_update_aim_from_mouse()

	target_position = target_position.move_toward(Vector2.RIGHT * max_length, cast_speed * delta)

	var laser_end_position: Vector2 = target_position
	force_raycast_update()

	if is_colliding():
		laser_end_position = to_local(get_collision_point())
		collision_particles.global_rotation = get_collision_normal().angle()
		collision_particles.global_position = get_collision_point()
	else:
		collision_particles.global_position = to_global(laser_end_position)

	line_2d.points[1] = laser_end_position

	var laser_start_position: Vector2 = line_2d.points[0]
	var beam_vector: Vector2 = laser_end_position - laser_start_position
	var beam_center: Vector2 = laser_start_position + beam_vector * 0.5
	var beam_length: float = beam_vector.length()

	beam_particles.position = beam_center

	var process_material: ParticleProcessMaterial = beam_particles.process_material as ParticleProcessMaterial
	if process_material:
		process_material.emission_box_extents.x = beam_length * 0.5

	_update_attack_area(laser_start_position, laser_end_position)

	collision_particles.emitting = is_colliding()


func _update_aim_from_mouse() -> void:
	if not is_casting:
		return

	if player == null:
		return

	var mouse_position: Vector2 = get_global_mouse_position()
	var aim_vector: Vector2 = mouse_position - global_position

	if aim_vector.length_squared() <= 0.001:
		return

	var aim_angle: float = aim_vector.angle()
	var forward_angle: float = 0.0 if facing_sign >= 0.0 else PI
	var half_cone: float = deg_to_rad(cone_angle_degrees * 0.5)

	var relative_angle: float = wrapf(aim_angle - forward_angle, -PI, PI)
	relative_angle = clamp(relative_angle, -half_cone, half_cone)

	global_rotation = forward_angle + relative_angle


func _update_attack_area(laser_start_position: Vector2, laser_end_position: Vector2) -> void:
	if not attack_area or not attack_area_shape:
		return

	var rect: RectangleShape2D = attack_area_shape.shape as RectangleShape2D
	if rect == null:
		return

	var beam_vector: Vector2 = laser_end_position - laser_start_position
	var beam_length: float = max(1.0, beam_vector.length())

	rect.size = Vector2(beam_length, hitbox_height)
	attack_area.position = laser_start_position + beam_vector * 0.5
	attack_area.rotation = beam_vector.angle()


func _on_attack_area_hit(other_attack_area: AttackArea) -> void:
	# Spawn a visual response when the beam touches another attack area.
	collision_particles.global_position = other_attack_area.global_position
	collision_particles.restart()
	collision_particles.emitting = true


func set_is_casting(new_value: bool) -> void:
	if is_casting == new_value:
		return

	is_casting = new_value
	set_physics_process(is_casting)

	if beam_particles == null:
		return

	beam_particles.emitting = is_casting
	casting_particles.emitting = is_casting

	if is_casting:
		var laser_start: Vector2 = Vector2.RIGHT * start_distance
		line_2d.points[0] = laser_start
		line_2d.points[1] = laser_start
		target_position = laser_start
		casting_particles.position = laser_start

		if attack_area:
			attack_area.set_active(true)

		appear()
	else:
		target_position = Vector2.ZERO
		collision_particles.emitting = false

		if attack_area:
			attack_area.set_active(false)

		disappear()


func appear() -> void:
	line_2d.visible = true

	if tween and tween.is_running():
		tween.kill()

	tween = create_tween()
	tween.tween_property(line_2d, "width", line_width, growth_time * 2.0).from(0.0)


func disappear() -> void:
	if tween and tween.is_running():
		tween.kill()

	tween = create_tween()
	tween.tween_property(line_2d, "width", 0.0, growth_time).from_current()
	tween.tween_callback(line_2d.hide)


func set_color(new_color: Color) -> void:
	color = new_color

	if line_2d == null:
		return

	line_2d.modulate = new_color
	casting_particles.modulate = new_color
	collision_particles.modulate = new_color
	beam_particles.modulate = new_color
