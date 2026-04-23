@icon("uid://2uubv1s8qxn5")
class_name DecisionEngine
extends Node

var enemy: Enemy
var current_state: EnemyState
var blackboard: Blackboard

func _ready() -> void:
	while not enemy:
		await get_tree().process_frame

	enemy.change_direction(-1.0 if enemy.face_left_on_start else 1.0)

func decide() -> EnemyState:
	return null
