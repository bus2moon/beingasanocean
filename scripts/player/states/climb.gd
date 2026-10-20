extends PlayerState
## Mantle up a ledge: rise along the wall, then pull forward onto the top.

const PULL_FRACTION := 0.3

var _start: Vector3
var _top: Vector3
var _end: Vector3
var _duration := 0.0
var _dir: Vector3


func enter(_from: StringName) -> void:
	var ledge := player.pending_ledge
	_dir = -ledge.wall_normal
	_start = player.global_position
	_end = ledge.end_point
	_top = Vector3(_start.x, _end.y + 0.05, _start.z)
	_duration = maxf(0.25, ledge.height * player.metrics.climb_time_per_meter) + 0.15
	player.velocity = Vector3.ZERO


func physics_update(delta: float) -> void:
	player.face_toward(_dir, delta, 20.0)
	var t := minf(machine.time_in_state / _duration, 1.0)
	var rise_end := 1.0 - PULL_FRACTION
	if t < rise_end:
		player.global_position = _start.lerp(_top, ease(t / rise_end, 0.6))
	else:
		player.global_position = _top.lerp(_end, (t - rise_end) / PULL_FRACTION)
	if t >= 1.0:
		var out := player.metrics.walk_speed if player.intent.move.length() > 0.1 else 0.0
		player.velocity = _dir * out + Vector3.DOWN
		player.move_and_slide()
		machine.transition(&"Move" if player.is_on_floor() else &"Fall")
