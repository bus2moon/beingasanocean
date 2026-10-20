extends Node
## Autoload "Settings". Owns the default input bindings so they live in code
## (diffable, testable) and can be rebound at runtime later.

const DEADZONE := 0.2

## action -> list of default events. Keys are physical keycodes, joypad uses
## the Xbox layout names Godot exposes (A = JOY_BUTTON_A, RB = RIGHT_SHOULDER).
var default_bindings := {
	"move_forward": [_key(KEY_W), _axis(JOY_AXIS_LEFT_Y, -1.0)],
	"move_back": [_key(KEY_S), _axis(JOY_AXIS_LEFT_Y, 1.0)],
	"move_left": [_key(KEY_A), _axis(JOY_AXIS_LEFT_X, -1.0)],
	"move_right": [_key(KEY_D), _axis(JOY_AXIS_LEFT_X, 1.0)],
	"look_up": [_axis(JOY_AXIS_RIGHT_Y, -1.0)],
	"look_down": [_axis(JOY_AXIS_RIGHT_Y, 1.0)],
	"look_left": [_axis(JOY_AXIS_RIGHT_X, -1.0)],
	"look_right": [_axis(JOY_AXIS_RIGHT_X, 1.0)],
	"jump": [_key(KEY_SPACE), _button(JOY_BUTTON_A)],
	"sprint": [_key(KEY_SHIFT), _button(JOY_BUTTON_RIGHT_SHOULDER)],
	"parkour": [_key(KEY_E), _button(JOY_BUTTON_X)],
	"toggle_debug": [_key(KEY_F3), _button(JOY_BUTTON_BACK)],
	"pause": [_key(KEY_ESCAPE), _button(JOY_BUTTON_START)],
}

var mouse_sensitivity := 0.0025
var stick_sensitivity := 3.0
var invert_y := false


func _enter_tree() -> void:
	apply_default_bindings()


func apply_default_bindings() -> void:
	for action: String in default_bindings:
		if not InputMap.has_action(action):
			InputMap.add_action(action, DEADZONE)
		InputMap.action_erase_events(action)
		for event: InputEvent in default_bindings[action]:
			InputMap.action_add_event(action, event)


static func _key(code: Key) -> InputEventKey:
	var e := InputEventKey.new()
	e.physical_keycode = code
	return e


static func _button(button: JoyButton) -> InputEventJoypadButton:
	var e := InputEventJoypadButton.new()
	e.button_index = button
	return e


static func _axis(axis: JoyAxis, value: float) -> InputEventJoypadMotion:
	var e := InputEventJoypadMotion.new()
	e.axis = axis
	e.axis_value = value
	return e
