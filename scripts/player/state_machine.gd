class_name StateMachine
extends Node
## Runs exactly one PlayerState child at a time.

signal state_changed(from: StringName, to: StringName)

@export var initial_state: StringName = &"Idle"

var current: PlayerState
var time_in_state := 0.0
var _states: Dictionary[StringName, PlayerState] = {}


func setup(player: Player) -> void:
	for child in get_children():
		if child is PlayerState:
			child.player = player
			child.machine = self
			_states[StringName(child.name)] = child
	current = _states[initial_state]
	current.enter(&"")


func transition(to: StringName) -> void:
	assert(_states.has(to), "Unknown state %s" % to)
	var from := StringName(current.name)
	current.exit(to)
	current = _states[to]
	time_in_state = 0.0
	current.enter(from)
	state_changed.emit(from, to)


func physics_update(delta: float) -> void:
	time_in_state += delta
	current.physics_update(delta)


func state_name() -> StringName:
	return StringName(current.name)
