@icon("uid://4nqrqjy1idov")
class_name Enemy
extends CharacterBody2D

@export var health: float = 3
@export var move_speed: float = 30
@export var face_left_on_start: bool = false

var dir: float = 1.0
var blackboard: Blackboard

var animation: AnimationPlayer
var sprite: Sprite2D
var damage_area: DamageArea
var hazard_area: HazardArea
var state_machine: EnemyStateMachine
var decision_engine: DecisionEngine

signal direction_changed(new_dir)
signal damage_taken
signal was_killed
signal was_hit

func _ready() -> void:
	if Engine.is_editor_hint():
		set_physics_process(false)
		return

	setup()

func setup() -> void:
	blackboard = Blackboard.new()
	blackboard.health = health

	for c in get_children():
		if c is AnimationPlayer and not animation:
			animation = c
		elif c is Sprite2D and not sprite:
			sprite = c
		elif c is DamageArea and not damage_area:
			damage_area = c
			c.damage_taken.connect(_on_damage_taken)
		elif c is HazardArea and not hazard_area:
			hazard_area = c
		elif c is EnemyStateMachine and not state_machine:
			state_machine = c
		elif c is DecisionEngine and not decision_engine:
			decision_engine = c

	if state_machine and decision_engine:
		state_machine.setup(self, blackboard)
		decision_engine.enemy = self
		decision_engine.blackboard = blackboard
	else:
		set_physics_process(false)

	change_direction(-1.0 if face_left_on_start else 1.0)

func _physics_process(delta: float) -> void:
	state_machine.change_state(decision_engine.decide())

	if is_on_floor():
		pass
	else:
		velocity.y += get_gravity() * delta

	state_machine.physics_update(delta)

	move_and_slide()

# ------------------------
# Direction + animation
# ------------------------

func change_direction(new_dir: float) -> void:
	blackboard.dir = new_dir
	direction_changed.emit(new_dir)

	if sprite:
		if new_dir < 0:
			sprite.flip_h = true
		elif new_dir > 0:
			sprite.flip_h = false

func play_animation(anim_name: String) -> void:
	if animation and animation.has_animation(anim_name):
		animation.play(anim_name)
	else:
		printerr("Animation missing: ", anim_name)

# ------------------------
# Damage handling
# ------------------------

func _on_damage_taken(a: AttackArea) -> void:
	blackboard.health -= a.damage

	if blackboard.health <= 0:
		damage_area.queue_free()
		hazard_area.queue_free()
		was_killed.emit()

	was_hit.emit(a)
