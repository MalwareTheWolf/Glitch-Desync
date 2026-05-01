class_name JoannaMovementController
extends Node

@onready var boss = get_parent()


func apply_gravity(delta: float) -> void:
	boss.velocity.y += boss.gravity * delta
	boss.velocity.y = clampf(boss.velocity.y, -1000.0, boss.max_fall_speed)


func stop_velocity() -> void:
	boss.velocity.x = 0.0


func stop_all_velocity() -> void:
	boss.velocity = Vector2.ZERO


func face_player() -> void:
	if boss.player == null:
		return

	var diff_x: float = boss.player.global_position.x - boss.global_position.x

	if abs(diff_x) <= boss.facing_deadzone:
		return

	var dir: int = int(sign(diff_x))

	if dir != 0:
		face_direction(dir)


func face_direction(dir: int) -> void:

	if boss.rest_locked:
		return

	if dir == 0:
		return

	boss.facing_dir = dir

	if boss.sprite_faces_right_by_default:
		boss.sprite.flip_h = dir < 0
	else:
		boss.sprite.flip_h = dir > 0

	if boss.thrust_hitbox != null:
		boss.thrust_hitbox.flip(float(dir))

	if boss.slash_hitbox != null:
		boss.slash_hitbox.flip(float(dir))

	if boss.dash_hitbox != null:
		boss.dash_hitbox.flip(float(dir))

	if boss.combo_hitbox != null:
		boss.combo_hitbox.flip(float(dir))

	if boss.air_above_hitbox != null:
		boss.air_above_hitbox.flip(float(dir))

	if dir != boss.last_facing_debug_dir:
		boss.last_facing_debug_dir = dir
		boss.debug_print("Facing changed. Dir:%s FlipH:%s" % [dir, boss.sprite.flip_h])


func chase_player(distance: float) -> void:
	if boss.rest_locked:
		return

	if boss.player == null:
		return

	var diff_x: float = boss.player.global_position.x - boss.global_position.x

	if abs(diff_x) <= boss.facing_deadzone:
		boss.velocity.x = 0.0
		boss.sprite.play("idle")
		return

	var dir: int = int(sign(diff_x))

	face_direction(dir)

	if distance >= boss.run_distance:
		boss.state = boss.BossState.RUN
		boss.velocity.x = float(boss.facing_dir) * boss.run_speed

		if not boss.was_running:
			play_run_start_dust()

		boss.was_running = true
		boss.sprite.play("run")
	else:
		boss.state = boss.BossState.WALK
		boss.velocity.x = float(boss.facing_dir) * boss.walk_speed
		boss.was_running = false
		boss.sprite.play("walk")


func should_jump_to_player(y_difference: float, x_distance: float) -> bool:
	if not boss.can_jump_attack:
		return false

	if not boss.is_on_floor():
		return false

	if y_difference < -boss.jump_y_difference and x_distance <= boss.platform_jump_x_range:
		boss.debug_print("Jumping up toward platform player. Y diff:%s X:%s" % [y_difference, x_distance])
		return true

	return false


func jump_to_player() -> void:

	if boss.rest_locked:
		return

	if boss.player == null:
		return

	boss.can_jump_attack = false
	boss.state = boss.BossState.JUMP

	var diff_x: float = boss.player.global_position.x - boss.global_position.x
	var dir: int = int(sign(diff_x))

	if dir != 0:
		face_direction(dir)

	boss.velocity.x = float(boss.facing_dir) * boss.run_speed * 1.15
	boss.velocity.y = boss.platform_jump_velocity

	boss.sprite.play("jump")

	await boss.get_tree().create_timer(boss.jump_cooldown).timeout
	boss.can_jump_attack = true


func is_wall_in_dash_direction(dir: int) -> bool:
	if dir == 0:
		return false

	var space_state: PhysicsDirectSpaceState2D = boss.get_world_2d().direct_space_state
	var from: Vector2 = boss.global_position
	var to: Vector2 = boss.global_position + Vector2(float(dir) * boss.dash_wall_check_distance, 0.0)
	var query: PhysicsRayQueryParameters2D = PhysicsRayQueryParameters2D.create(from, to)

	query.exclude = [boss]
	query.collision_mask = boss.collision_mask

	var result: Dictionary = space_state.intersect_ray(query)

	return not result.is_empty()


func play_run_start_dust() -> void:
	if not boss.has_node("RunDustVFX"):
		return

	var dust: AnimatedSprite2D = boss.get_node("RunDustVFX") as AnimatedSprite2D

	dust.visible = true
	dust.flip_h = boss.sprite.flip_h
	dust.position.x = -12.0 * float(boss.facing_dir)
	dust.play("run_dust")
