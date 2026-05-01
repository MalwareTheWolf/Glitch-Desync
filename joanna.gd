extends CharacterBody2D

signal boss_started
signal health_changed(current_hp: float, max_hp: float)
signal phase_two_started
signal boss_defeated

enum BossState {
	IDLE,
	INTRO,
	WALK,
	RUN,
	CIRCLE,
	TURN,
	JUMP,
	ATTACK,
	HEAL,
	BUFF,
	PHASE_TWO,
	DEAD
}

@export_group("Debug")
@export var debug_enabled: bool = true
@export var fallback_detection_range: float = 250.0

@export_group("Stats")
@export var max_hp: float = 600.0
@export var phase_two_hp_threshold: float = 0.5
@export_group("Attack Spacing")
@export var min_time_between_attacks: float = 1.4
@export var combo_recovery_time: float = 0.35

@export_group("Half HP Rules")
@export var holy_unlock_hp_threshold: float = 0.5

@export_group("Heal Interrupt")
@export var heal_knockback_force: float = 180.0
@export var heal_cancel_recovery: float = 0.4
@export_group("Healing")
@export var small_heal_hp_threshold: float = 0.65
@export var small_heal_amount: float = 60.0
@export var small_heal_max_uses: int = 2

@export var big_heal_hp_threshold: float = 0.35
@export var big_heal_amount: float = 150.0
@export var big_heal_max_uses: int = 1

@export_group("Movement")
@export var walk_speed: float = 55.0
@export var run_speed: float = 115.0
@export var dash_speed: float = 320.0
@export var jump_velocity: float = -310.0
@export var gravity: float = 900.0
@export var stop_distance: float = 55.0
@export var run_distance: float = 180.0
@export var ideal_circle_distance: float = 115.0
@export var circle_speed: float = 45.0
@export var jump_y_difference: float = 45.0

@export_group("Boss AI")
@export var attack_cooldown: float = 1.2
@export var phase_two_attack_cooldown: float = 0.75
@export var max_buffs: int = 2
@export var buff_speed_multiplier: float = 1.15
@export var buff_damage_multiplier: float = 1.15

@export_group("Attack Ranges")
@export var slash_range: float = 75.0
@export var thrust_range: float = 95.0
@export var dash_range: float = 220.0
@export var holy_range: float = 260.0

@export_group("Attack Damage")
@export var slash_damage: float = 25.0
@export var thrust_damage: float = 30.0
@export var dash_damage: float = 35.0
@export var holy_damage: float = 40.0

@export_group("Attack Timing")
@export var slash_startup: float = 0.35
@export var slash_active_time: float = 0.18
@export var thrust_startup: float = 0.25
@export var thrust_active_time: float = 0.16
@export var dash_startup: float = 0.20

@export_group("Boss Intro")
@export var intro_duration: float = 1.0
@export var required_dialog_id: String = "boss_intro"
@export var require_dialog_before_start: bool = true

@export_group("Scenes")
@export var holy_projectile_scene: PackedScene
@export var slam_wave_scene: PackedScene

@export_group("Jump Control")
@export var allow_gap_jump: bool = false
@export var jump_attack_chance: int = 15
@export var jump_cooldown: float = 3.0

@export_group("Dash Control")
@export var dash_overshoot_distance: float = 90.0
@export var dash_wall_check_distance: float = 18.0
@export var dash_max_time: float = 0.75

@export_group("Holy Attack Rules")
@export var holy_attacks_hp_threshold: float = 0.5
@export var mid_range_attack_chance: int = 45

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

@onready var thrust_hitbox: AttackArea = $thrust
@onready var slash_hitbox: AttackArea = $holy_slash
@onready var dash_hitbox: AttackArea = $holy_dash

@onready var damageable_area: DamageableArea = $DamageableArea
@onready var attack_timer: Timer = $attack_timer
@onready var player_detector: Area2D = $PlayerDetector
@onready var floor_detector: RayCast2D = $FloorDetector
@onready var state_label: Label = $StateLabel
@onready var boss_music_player: AudioStreamPlayer = $BossMusicPlayer

var current_hp: float = 0.0
var state: BossState = BossState.IDLE
var last_debug_state: BossState = BossState.IDLE
var can_jump_attack: bool = true
var player: Node2D = null
var player_inside_detector: bool = false
var active: bool = false
var intro_playing: bool = false
var dead: bool = false
var attacking: bool = false
var can_attack: bool = true
var phase_two: bool = false
var facing_dir: int = 1
var circle_dir: int = 1
var small_heals_used: int = 0
var big_heals_used: int = 0
var buffs_used: int = 0
var buffed: bool = false
var was_running: bool = false
var heal_interrupted: bool = false
var last_attack_name: String = ""
var has_reached_half_hp_once: bool = false
var heal_locked: bool = false
var attack_spacing_locked: bool = false
var animation_offsets: Dictionary[String, Vector2] = {
	"holy_slash": Vector2(15.0, -30.0)
}


func _ready() -> void:
	current_hp = max_hp

	disable_all_hitboxes()

	attack_timer.wait_time = attack_cooldown
	attack_timer.one_shot = true
	attack_timer.timeout.connect(_on_attack_timer_timeout)

	player_detector.body_entered.connect(_on_player_detector_body_entered)
	damageable_area.damage_taken.connect(_on_damage_taken)

	health_changed.emit(current_hp, max_hp)
	sprite.play("idle")

	player_detector.body_exited.connect(_on_player_detector_body_exited)

	debug_print("READY. Boss loaded. HP: %s" % current_hp)


func _physics_process(delta: float) -> void:
	if dead:
		update_state_label()
		return

	apply_gravity(delta)
	update_sprite_offset()
	update_state_label()
	debug_state_change()

	if player == null:
		player = find_player()

	if not active and player != null:
		var distance_to_player: float = global_position.distance_to(player.global_position)

		if player_inside_detector and can_start_boss_fight():
			start_boss_fight()
			return

		if distance_to_player <= fallback_detection_range and can_start_boss_fight():
			start_boss_fight()
			return

	if not active or intro_playing:
		velocity.x = 0.0
		move_and_slide()
		return

	if player == null:
		move_and_slide()
		return

	if attacking:
		move_and_slide()
		return

	boss_ai()
	move_and_slide()


func can_start_boss_fight() -> bool:
	if not require_dialog_before_start:
		return true

	if required_dialog_id.strip_edges() == "":
		return true

	return SaveManager.has_flag("dialog_" + required_dialog_id)


func find_player() -> Node2D:
	var lower_player: Node = get_tree().get_first_node_in_group("player")
	if lower_player is Node2D:
		return lower_player as Node2D

	var upper_player: Node = get_tree().get_first_node_in_group("Player")
	if upper_player is Node2D:
		return upper_player as Node2D

	return null


func apply_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity.y += gravity * delta


func boss_ai() -> void:
	var distance: float = global_position.distance_to(player.global_position)
	var y_difference: float = player.global_position.y - global_position.y
	var new_dir: int = int(sign(player.global_position.x - global_position.x))

	face_player()

	if not has_reached_half_hp_once and current_hp <= max_hp * holy_unlock_hp_threshold:
		has_reached_half_hp_once = true
		debug_print("Holy attacks unlocked permanently.")

	if new_dir != 0 and new_dir != facing_dir and state != BossState.TURN:
		play_turn(new_dir)
		return

	if not phase_two and current_hp <= max_hp * phase_two_hp_threshold:
		enter_phase_two()
		return

	var heal_type: String = choose_heal_type()
	if heal_type != "":
		do_heal(heal_type)
		return

	if should_buff():
		do_buff()
		return

	if distance > holy_range:
		chase_player(distance)
		return

	if attack_spacing_locked:
		circle_player()
		return

	if can_attack:
		if has_reached_half_hp_once:
			execute_combo(pick_unlocked_combo())
		else:
			execute_combo(pick_phase_one_combo())
		return

	circle_player()


func start_boss_fight() -> void:
	if active:
		return

	if not can_start_boss_fight():
		return

	active = true
	intro_playing = true
	state = BossState.INTRO
	velocity = Vector2.ZERO

	boss_started.emit()

	if boss_music_player != null and not boss_music_player.playing:
		boss_music_player.play()

	debug_print("BOSS INTRO STARTED")
	sprite.play("idle")

	await get_tree().create_timer(intro_duration).timeout

	intro_playing = false
	state = BossState.IDLE
	debug_print("BOSS FIGHT STARTED")


func _on_player_detector_body_entered(body: Node2D) -> void:
	debug_print("PlayerDetector touched body: %s groups: %s" % [body.name, body.get_groups()])

	if body.is_in_group("player") or body.is_in_group("Player"):
		player = body
		player_inside_detector = true

		if can_start_boss_fight():
			start_boss_fight()


func _on_attack_timer_timeout() -> void:
	can_attack = true


func chase_player(distance: float) -> void:
	var dir: int = int(sign(player.global_position.x - global_position.x))

	if dir == 0:
		return

	face_direction(dir)

	if distance >= run_distance:
		state = BossState.RUN
		velocity.x = float(facing_dir) * run_speed

		if not was_running:
			play_run_start_dust()

		was_running = true
		sprite.play("run")
	else:
		state = BossState.WALK
		velocity.x = float(facing_dir) * walk_speed
		was_running = false
		sprite.play("walk")


func circle_player() -> void:
	state = BossState.CIRCLE
	was_running = false

	var x_distance: float = abs(player.global_position.x - global_position.x)

	if x_distance < ideal_circle_distance - 20.0:
		velocity.x = -float(facing_dir) * circle_speed
	elif x_distance > ideal_circle_distance + 20.0:
		velocity.x = float(facing_dir) * walk_speed
	else:
		velocity.x = float(circle_dir) * circle_speed

	face_player()
	sprite.play("walk")


func should_jump_to_player(y_difference: float) -> bool:
	if not is_on_floor():
		return false

	# Jump if player is clearly above Joanna.
	if y_difference < -jump_y_difference:
		return true

	# Gap jump is optional because RayCast2D setup can cause spam jumping.
	if allow_gap_jump and floor_detector != null and not floor_detector.is_colliding():
		return true

	return false


func jump_to_player() -> void:
	can_jump_attack = false
	state = BossState.JUMP
	was_running = false

	var dir: int = int(sign(player.global_position.x - global_position.x))

	if dir != 0:
		face_direction(dir)
		velocity.x = float(facing_dir) * run_speed

	velocity.y = jump_velocity
	sprite.play("jump")

	await get_tree().create_timer(0.35).timeout

	if not dead and active:
		attacking = true
		await do_aerial_attack()
		attacking = false
		state = BossState.IDLE

	await get_tree().create_timer(jump_cooldown).timeout
	can_jump_attack = true


func play_turn(new_dir: int) -> void:
	if attacking or dead:
		return

	state = BossState.TURN
	attacking = true
	velocity.x = 0.0
	was_running = false

	var anim: String = "turn_right1"

	if randi() % 2 == 1:
		anim = "turn_right2"

	sprite.flip_h = new_dir > 0
	sprite.play(anim)

	await sprite.animation_finished

	face_direction(new_dir)
	attacking = false
	state = BossState.IDLE


func pick_attack_without_repeat(attacks: Array[String]) -> String:
	if attacks.size() <= 1:
		last_attack_name = attacks[0]
		return attacks[0]

	var filtered: Array[String] = []

	for attack_name: String in attacks:
		if attack_name != last_attack_name:
			filtered.append(attack_name)

	if filtered.is_empty():
		filtered = attacks

	var chosen: String = filtered.pick_random()
	last_attack_name = chosen
	return chosen

func pick_phase_one_mid_combo() -> Array[String]:
	var possible: Array[String] = ["dash", "thrust"]
	var chosen: String = pick_attack_without_repeat(possible)

	return [chosen]

func pick_phase_one_combo() -> Array[String]:
	var possible: Array[String] = ["air_above_attack", "air_attack", "combo_1"]
	var chosen: String = pick_attack_without_repeat(possible)

	return [chosen]


func pick_phase_two_combo() -> Array[String]:
	var possible: Array[String] = ["slash", "thrust", "dash"]

	if can_use_holy_attacks():
		possible.append("holy")
		possible.append("jump_attack")

	var chosen: String = pick_attack_without_repeat(possible)

	match chosen:
		"slash":
			return ["slash", "thrust", "dash"]
		"thrust":
			return ["thrust", "slash"]
		"dash":
			return ["dash", "slash"]
		"holy":
			return ["holy", "dash"]
		"jump_attack":
			return ["jump_attack", "dash"]

	return ["slash"]

func pick_phase_two_mid_combo() -> Array[String]:
	var possible: Array[String] = ["dash", "thrust"]

	if can_use_holy_attacks():
		possible.append("holy")

	var chosen: String = pick_attack_without_repeat(possible)

	match chosen:
		"dash":
			return ["dash", "slash"]
		"holy":
			return ["holy"]
		"thrust":
			return ["thrust"]

	return ["dash"]

func pick_unlocked_combo() -> Array[String]:
	var possible: Array[String] = [
		"air_above_attack",
		"air_attack",
		"combo_1",
		"holy_dash",
		"holy_projectile"
	]

	var chosen: String = pick_attack_without_repeat(possible)

	match chosen:
		"holy_dash":
			return ["holy_dash", "combo_1"]
		"holy_projectile":
			return ["holy_projectile"]
		_:
			return [chosen]

func execute_combo(combo: Array[String]) -> void:
	if attacking or dead or attack_spacing_locked:
		return

	can_attack = false
	attack_spacing_locked = true
	attack_timer.start()
	attacking = true
	was_running = false

	debug_print("Combo started: %s" % combo)

	for attack_name: String in combo:
		if dead or player == null:
			break

		face_player()

		match attack_name:
			"air_above_attack":
				await do_air_above_attack()
			"air_attack":
				await do_air_attack()
			"combo_1":
				await do_combo_1()
			"holy_dash":
				await do_holy_dash_attack()
			"holy_projectile":
				await do_holy_attack()

		disable_all_hitboxes()
		await get_tree().create_timer(combo_recovery_time).timeout

	attacking = false
	state = BossState.IDLE

	await get_tree().create_timer(min_time_between_attacks).timeout
	attack_spacing_locked = false

	debug_print("Combo finished")


func do_slash_attack() -> void:
	state = BossState.ATTACK
	stop_velocity()
	face_player()

	sprite.play("holy_slash")

	await get_tree().create_timer(slash_startup).timeout

	disable_all_hitboxes()
	slash_hitbox.damage = slash_damage
	slash_hitbox.flip(float(facing_dir))
	slash_hitbox.activate(slash_active_time)

	await sprite.animation_finished
	disable_all_hitboxes()


func do_thrust_attack() -> void:
	state = BossState.ATTACK
	stop_velocity()
	face_player()

	sprite.play("thrust_attack")

	await get_tree().create_timer(thrust_startup).timeout

	disable_all_hitboxes()
	thrust_hitbox.damage = thrust_damage
	thrust_hitbox.flip(float(facing_dir))
	thrust_hitbox.activate(thrust_active_time)

	await sprite.animation_finished
	disable_all_hitboxes()


func do_holy_dash_attack() -> void:
	if not has_reached_half_hp_once:
		await do_combo_1()
		return

	state = BossState.ATTACK
	face_player()

	var dir: int = facing_dir
	var desired_x: float = player.global_position.x + float(dir) * dash_overshoot_distance
	var dash_time: float = 0.0

	stop_velocity()
	sprite.play("holy_dash_attack")

	# Startup stays still.
	await get_tree().create_timer(dash_startup).timeout

	disable_all_hitboxes()
	dash_hitbox.damage = dash_damage
	dash_hitbox.flip(float(dir))
	dash_hitbox.set_active(true)

	while abs(global_position.x - desired_x) > 10.0 and not dead:
		if is_wall_in_dash_direction(dir):
			debug_print("Dash hit wall.")
			break

		velocity.x = float(dir) * dash_speed
		move_and_slide()

		dash_time += get_physics_process_delta_time()
		if dash_time >= dash_max_time:
			break

		await get_tree().physics_frame

	velocity.x = 0.0
	dash_hitbox.set_active(false)

	if not is_wall_in_dash_direction(dir):
		global_position.x = desired_x

	await sprite.animation_finished
	disable_all_hitboxes()


func do_holy_attack() -> void:
	if not has_reached_half_hp_once:
		await do_combo_1()
		return

	state = BossState.ATTACK
	stop_velocity()
	face_player()

	sprite.play("holy_big_heal")

	await get_tree().create_timer(0.55).timeout
	spawn_holy_projectile()

	await sprite.animation_finished


func do_air_above_attack() -> void:
	state = BossState.ATTACK
	face_player()

	var target_position: Vector2 = player.global_position + Vector2(0.0, -80.0)

	sprite.play("air_above_attack")

	global_position = target_position
	velocity = Vector2.ZERO

	await get_tree().create_timer(0.25).timeout

	face_player()
	velocity.y = 260.0

	disable_all_hitboxes()
	slash_hitbox.damage = slash_damage
	slash_hitbox.flip(float(facing_dir))
	slash_hitbox.activate(0.22)

	await sprite.animation_finished
	disable_all_hitboxes()
	velocity = Vector2.ZERO

func do_air_attack() -> void:
	state = BossState.ATTACK
	face_player()

	var dir: int = facing_dir

	sprite.play("air_attack")

	velocity.x = float(dir) * run_speed * 1.5
	velocity.y = jump_velocity * 0.55

	await get_tree().create_timer(0.22).timeout

	disable_all_hitboxes()
	thrust_hitbox.damage = thrust_damage
	thrust_hitbox.flip(float(dir))
	thrust_hitbox.activate(0.25)

	await sprite.animation_finished
	disable_all_hitboxes()
	velocity.x = 0.0

func do_combo_1() -> void:
	state = BossState.ATTACK
	stop_velocity()
	face_player()

	sprite.play("combo_1")

	await get_tree().create_timer(0.18).timeout

	disable_all_hitboxes()
	thrust_hitbox.damage = thrust_damage
	thrust_hitbox.flip(float(facing_dir))
	thrust_hitbox.activate(0.16)

	await get_tree().create_timer(0.22).timeout

	face_player()
	disable_all_hitboxes()
	thrust_hitbox.damage = thrust_damage
	thrust_hitbox.flip(float(facing_dir))
	thrust_hitbox.activate(0.16)

	await get_tree().create_timer(0.22).timeout

	face_player()
	disable_all_hitboxes()
	slash_hitbox.damage = slash_damage
	slash_hitbox.flip(float(facing_dir))
	slash_hitbox.activate(0.18)

	await sprite.animation_finished
	disable_all_hitboxes()




func choose_heal_type() -> String:
	if heal_locked:
		return ""

	if attacking:
		return ""

	if not can_attack:
		return ""

	var hp_percent: float = current_hp / max_hp

	if hp_percent <= big_heal_hp_threshold and big_heals_used < big_heal_max_uses:
		return "big"

	if hp_percent <= small_heal_hp_threshold and small_heals_used < small_heal_max_uses:
		return "small"

	return ""


func do_heal(heal_type: String) -> void:
	if heal_locked:
		return

	attacking = true
	can_attack = false
	heal_locked = true
	attack_timer.start()
	state = BossState.HEAL
	stop_velocity()

	heal_interrupted = false

	var amount: float = 0.0

	if heal_type == "big":
		big_heals_used += 1
		amount = big_heal_amount
		sprite.play("holy_big_heal")
	else:
		small_heals_used += 1
		amount = small_heal_amount
		sprite.play("holy_heal")

	await sprite.animation_finished

	if dead:
		return

	if heal_interrupted:
		debug_print("Heal interrupted. No HP restored.")
		await get_tree().create_timer(heal_cancel_recovery).timeout
		attacking = false
		state = BossState.IDLE
		heal_locked = false
		return

func spawn_holy_projectile() -> void:
	if holy_projectile_scene == null:
		debug_print("holy_projectile_scene is not assigned.")
		return

	var projectile: Node = holy_projectile_scene.instantiate()
	get_tree().current_scene.add_child(projectile)

	if projectile is Node2D:
		var projectile_2d: Node2D = projectile as Node2D
		projectile_2d.global_position = global_position + Vector2(30.0 * float(facing_dir), -20.0)

	projectile.set("direction", (player.global_position - global_position).normalized())
	projectile.set("damage", holy_damage)

	current_hp = min(current_hp + amount, max_hp)
	health_changed.emit(current_hp, max_hp)

	debug_print("Heal completed. Restored: %s" % amount)

	attacking = false
	state = BossState.IDLE
	heal_locked = false

	await get_tree().create_timer(min_time_between_attacks).timeout


func should_buff() -> bool:
	if buffs_used >= max_buffs:
		return false

	if buffed:
		return false

	if current_hp > max_hp * 0.65:
		return false

	if not can_attack:
		return false

	return randi() % 100 < 25


func do_buff() -> void:
	attacking = true
	can_attack = false
	attack_timer.start()
	state = BossState.BUFF
	stop_velocity()

	buffs_used += 1
	sprite.play("holy_buff")

	await sprite.animation_finished

	if dead:
		return

	buffed = true

	walk_speed *= buff_speed_multiplier
	run_speed *= buff_speed_multiplier
	dash_speed *= buff_speed_multiplier
	circle_speed *= buff_speed_multiplier

	slash_damage *= buff_damage_multiplier
	thrust_damage *= buff_damage_multiplier
	dash_damage *= buff_damage_multiplier
	holy_damage *= buff_damage_multiplier

	attacking = false
	state = BossState.IDLE

	debug_print("Buff completed. Stats increased.")


func enter_phase_two() -> void:
	phase_two = true
	state = BossState.PHASE_TWO
	attacking = true
	stop_velocity()
	disable_all_hitboxes()

	debug_print("PHASE TWO STARTED")

	sprite.play("holy_buff")

	await sprite.animation_finished

	if dead:
		return

	walk_speed *= 1.2
	run_speed *= 1.25
	dash_speed *= 1.2
	circle_speed *= 1.25

	slash_damage *= 1.25
	thrust_damage *= 1.25
	dash_damage *= 1.25
	holy_damage *= 1.25

	attack_timer.wait_time = phase_two_attack_cooldown
	circle_dir *= -1

	phase_two_started.emit()

	attacking = false
	state = BossState.IDLE

func spawn_slam_wave() -> void:
	if slam_wave_scene == null:
		debug_print("slam_wave_scene is not assigned.")
		return

	var wave: Node = slam_wave_scene.instantiate()
	get_tree().current_scene.add_child(wave)

	if wave is Node2D:
		var wave_2d: Node2D = wave as Node2D
		wave_2d.global_position = global_position + Vector2(35.0 * float(facing_dir), 0.0)

	wave.set("damage", holy_damage)


func _on_damage_taken(attack_area: AttackArea) -> void:
	if dead:
		return

	if state == BossState.HEAL:
		heal_interrupted = true
		cancel_heal_with_knockback(attack_area)

	take_damage(attack_area.damage)


func take_damage(amount: float) -> void:
	if dead:
		return

	current_hp -= amount
	current_hp = max(current_hp, 0.0)
	health_changed.emit(current_hp, max_hp)

	debug_print("HP: %s/%s" % [current_hp, max_hp])

	if current_hp <= 0.0:
		die()
		return

	flash_damage()


func flash_damage() -> void:
	sprite.modulate = Color.RED
	await get_tree().create_timer(0.08).timeout

	if not dead:
		sprite.modulate = Color.WHITE


func die() -> void:
	dead = true
	active = false
	intro_playing = false
	attacking = false
	state = BossState.DEAD

	stop_velocity()
	disable_all_hitboxes()

	if boss_music_player != null and boss_music_player.playing:
		boss_music_player.stop()

	debug_print("Boss defeated.")

	sprite.play("death")
	boss_defeated.emit()

	await sprite.animation_finished

	sprite.pause()


func disable_all_hitboxes() -> void:
	if thrust_hitbox != null:
		thrust_hitbox.set_active(false)

	if slash_hitbox != null:
		slash_hitbox.set_active(false)

	if dash_hitbox != null:
		dash_hitbox.set_active(false)


func face_player() -> void:
	if player == null:
		return

	var dir: int = int(sign(player.global_position.x - global_position.x))

	if dir != 0:
		face_direction(dir)


func face_direction(dir: int) -> void:
	if dir == 0:
		return

	facing_dir = dir

	# Joanna faces left by default.
	sprite.flip_h = dir > 0

	thrust_hitbox.flip(float(dir))
	slash_hitbox.flip(float(dir))
	dash_hitbox.flip(float(dir))


func stop_velocity() -> void:
	velocity.x = 0.0


func update_sprite_offset() -> void:
	var offset: Vector2 = animation_offsets.get(sprite.animation, Vector2.ZERO) as Vector2

	if sprite.flip_h:
		offset.x *= -1.0

	sprite.offset = offset


func play_run_start_dust() -> void:
	if not has_node("RunDustVFX"):
		return

	var dust: AnimatedSprite2D = $RunDustVFX

	dust.visible = true
	dust.flip_h = sprite.flip_h
	dust.position.x = -12.0 * float(facing_dir)
	dust.play("run_dust")

func is_wall_in_dash_direction(dir: int) -> bool:
	if dir == 0:
		return false

	var space_state: PhysicsDirectSpaceState2D = get_world_2d().direct_space_state

	var from: Vector2 = global_position
	var to: Vector2 = global_position + Vector2(float(dir) * dash_wall_check_distance, 0.0)

	var query: PhysicsRayQueryParameters2D = PhysicsRayQueryParameters2D.create(from, to)
	query.exclude = [self]
	query.collision_mask = collision_mask

	var result: Dictionary = space_state.intersect_ray(query)

	return not result.is_empty()

func can_use_holy_attacks() -> bool:
	return current_hp <= max_hp * holy_attacks_hp_threshold

func update_state_label() -> void:
	if state_label == null:
		return

	var state_name: String = BossState.keys()[state]

	state_label.text = "State: %s\nPhase 2: %s\nHP: %s/%s\nCan Attack: %s\nAttacking: %s\nSmall Heals: %s/%s\nBig Heals: %s/%s" % [
		state_name,
		phase_two,
		current_hp,
		max_hp,
		can_attack,
		attacking,
		small_heals_used,
		small_heal_max_uses,
		big_heals_used,
		big_heal_max_uses
	]


func debug_state_change() -> void:
	if not debug_enabled:
		return

	if state != last_debug_state:
		debug_print("State changed: %s -> %s" % [
			BossState.keys()[last_debug_state],
			BossState.keys()[state]
		])
		last_debug_state = state

func _on_player_detector_body_exited(body: Node2D) -> void:
	if body.is_in_group("player") or body.is_in_group("Player"):
		player_inside_detector = false

func debug_print(message: String) -> void:
	if debug_enabled:
		print("[JoannaBoss] ", message)
