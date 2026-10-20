class_name InputBuffer
extends RefCounted
## Remembers presses for a short window so a jump pressed just before landing
## (or just before reaching a ledge) still happens.

var _pressed_at: Dictionary[StringName, float] = {}
var _clock := 0.0


func tick(delta: float) -> void:
	_clock += delta


func press(action: StringName) -> void:
	_pressed_at[action] = _clock


## True if `action` was pressed within `window` seconds; consumes it.
func consume(action: StringName, window: float) -> bool:
	if not _pressed_at.has(action):
		return false
	var fresh := _clock - _pressed_at[action] <= window
	_pressed_at.erase(action)
	return fresh


func peek(action: StringName, window: float) -> bool:
	return _pressed_at.has(action) and _clock - _pressed_at[action] <= window
