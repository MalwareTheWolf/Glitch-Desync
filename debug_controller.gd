class_name JoannaDebugController
extends Node

@onready var boss = get_parent()


func update_state_label() -> void:
	if boss.state_label == null:
		return

	var state_name: String = boss.BossState.keys()[boss.state]
	var detail: String = get_state_detail()

	var now_msec: int = Time.get_ticks_msec()
	var heal_elapsed: float = float(now_msec - boss.last_heal_time_msec) / 1000.0

	boss.state_label.text = "State: %s\n%s\nHP: %s/%s\nHoly Unlocked: %s\nCan Attack: %s\nAttacking: %s\nHeal CD: %.1f/%s\nSmall Heals: %s/%s\nBig Heals: %s/%s" % [
		state_name,
		detail,
		boss.current_hp,
		boss.max_hp,
		boss.has_reached_half_hp_once,
		boss.can_attack,
		boss.attacking,
		heal_elapsed,
		boss.heal_cooldown,
		boss.small_heals_used,
		boss.small_heal_max_uses,
		boss.big_heals_used,
		boss.big_heal_max_uses
	]


func get_state_detail() -> String:
	match boss.state:
		boss.BossState.IDLE:
			return "Ready / deciding"

		boss.BossState.INTRO:
			return "Intro playing"

		boss.BossState.WALK:
			return "Charging toward player"

		boss.BossState.RUN:
			return "Running toward player"

		boss.BossState.JUMP:
			return "Jumping toward player"

		boss.BossState.ATTACK:
			return "Attack: %s" % boss.sprite.animation

		boss.BossState.REST:
			return "Rest animation"

		boss.BossState.HEAL:
			return "Healing | Interrupted: %s | Locked: %s" % [
				boss.heal_interrupted,
				boss.heal_locked
			]

		boss.BossState.BUFF:
			return "Buffing"

		boss.BossState.PHASE_TWO:
			return "Entering phase 2"

		boss.BossState.DEAD:
			return "Defeated"

	return "Unknown state"


func debug_state_change() -> void:
	if not boss.debug_enabled:
		return

	if boss.state != boss.last_debug_state:
		boss.debug_print("State changed: %s -> %s" % [
			boss.BossState.keys()[boss.last_debug_state],
			boss.BossState.keys()[boss.state]
		])

		boss.last_debug_state = boss.state


func print_hitbox_snapshot() -> void:
	if not boss.debug_enabled:
		return

	boss.debug_print("HITBOX SNAPSHOT | thrust:%s slash:%s dash:%s combo:%s above:%s" % [
		get_hitbox_status(boss.thrust_hitbox),
		get_hitbox_status(boss.slash_hitbox),
		get_hitbox_status(boss.dash_hitbox),
		get_hitbox_status(boss.combo_hitbox),
		get_hitbox_status(boss.air_above_hitbox)
	])


func get_hitbox_status(hitbox: AttackArea) -> String:
	if hitbox == null:
		return "NULL"

	return "active:%s visible:%s pos:%s dmg:%s" % [
		hitbox.monitoring,
		hitbox.visible,
		hitbox.position,
		hitbox.damage
	]
