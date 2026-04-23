@icon("uid://4nnkv3j2sut0")
class_name EnemyStateMachine
extends Node

var enemy: Enemy
var blackboard: Blackboard

var states: Array[EnemyState] = []

var current_state: EnemyState:
	get:
		return states.front()

var prev_state: EnemyState:
	get:
		if states.size() > 1:
			return states.get(1)
		return null

func setup(e: Enemy, b: Blackboard) -> void:
	enemy = e
	blackboard = b

	for c in get_children():
		if c is EnemyState:
			c.enemy = e
			c.blackboard = b
			c.state_machine = self
			states.append(c)

	if states.size() > 0:
		current_state.enter()

func change_state(new_state: EnemyState) -> void:
	if not new_state:
		return

	if new_state == current_state:
		current_state.re_enter()
		return

	if current_state:
		current_state.exit()

	states.push_front(new_state)

	current_state.enter()

	if enemy:
		enemy.decision_engine.current_state = new_state

	states.resize(2)

func physics_update(delta: float) -> void:
	if current_state:
		current_state.physics_update(delta)
