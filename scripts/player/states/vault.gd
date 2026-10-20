extends PlayerState
## Vault over a low thin obstacle, or step-vault onto a low deep one. Scripted
## arc (code drives position) so it is fast and exact; speed carries through.

var _start: Vector3
var _control: Vector3
var _end: Vector3
var _duration := 0.0
var _exit_speed := 0.0
var _dir: Vector3


func enter(_from: StringName) -> void:
	var ledge := player.pending_ledge
	var m := player.metrics
	_start = player.global_position
	_end = ledge.end_point
	_dir = -ledge.wall_normal
	# Quadratic bezier whose midpoint clears the edge by a hand's height.
	var peak := ledge.edge_point + Vector3.UP * 0.2
	_control = peak * 2.0 - (_start + _end) * 0.5
	var stepping := ledge.kind == TraversalSensors.Kind.STEP_UP
	_duration = m.vault_time * (0.8 if stepping else 1.0)
	_exit_speed = maxf(player.horizontal_speed(), m.jog_speed if player.intent.move.length() > 0.1 else 0.0)
	player.velocity = Vector3.ZERO


func physics_update(delta: float) -> void:
	player.face_toward(_dir, delta, 20.0)
	var t := minf(machine.time_in_state / _duration, 1.0)
	var a := _start.lerp(_control, t)
	var b := _control.lerp(_end, t)
	player.global_position = a.lerp(b, t)
	if t >= 1.0:
		player.velocity = _dir * _exit_speed + Vector3.DOWN
		player.move_and_slide()
		machine.transition(&"Move" if player.is_on_floor() else &"Fall")
