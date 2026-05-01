@icon("uid://d2qa0x0tpfgll")
class_name AttackArea
extends Area2D

# Hitbox used to deal damage to DamageableArea objects.
# Can be activated briefly during attacks.

signal attack_area_hit(other_attack_area: AttackArea)

@export var damage: float = 1.0
@export var spawn_hit_dust: bool = true

# Stores the hitbox's original local position.
# This lets flip() move the hitbox to the correct side of the character.
var starting_position: Vector2 = Vector2.ZERO


func _ready() -> void:
	starting_position = position

	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)

	# Start disabled.
	visible = false
	monitoring = false


func _on_body_entered(body: Node2D) -> void:
	if not monitoring:
		return

	if body is DamageableArea:
		_apply_damage(body)


func _on_area_entered(area: Area2D) -> void:
	if not monitoring:
		return

	if area == self:
		return

	if area is DamageableArea:
		_apply_damage(area)
	elif area is AttackArea:
		attack_area_hit.emit(area)


func _apply_damage(target: DamageableArea) -> void:
	target.take_damage(self)

	if spawn_hit_dust:
		var pos: Vector2 = global_position
		pos.x = target.global_position.x
		VisualEffects.hit_dust(pos)


func activate(duration: float = 0.1) -> void:
	set_active(true)
	await get_tree().create_timer(duration).timeout
	set_active(false)


func set_active(value: bool = true) -> void:
	monitoring = value
	visible = value


func flip(direction_x: float) -> void:
	var dir: float = sign(direction_x)

	if dir == 0.0:
		return

	# Move the hitbox to the correct side instead of relying on negative scale.
	position.x = abs(starting_position.x) * dir

	# Keep scale positive so collision/debug visuals stay predictable.
	scale.x = abs(scale.x)
