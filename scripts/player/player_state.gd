class_name PlayerState
extends Node
## Base for one movement state. States are child nodes of the StateMachine and
## are named by their node name (Idle, Move, Jump ...).

var player: Player
var machine: StateMachine


func enter(_from: StringName) -> void:
	pass


func exit(_to: StringName) -> void:
	pass


func physics_update(_delta: float) -> void:
	pass
