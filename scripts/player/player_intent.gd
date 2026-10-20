class_name PlayerIntent
extends RefCounted
## One physics tick of player intent. Filled from devices by Player, or set
## directly by tests / cutscenes / AI so movement code never touches Input.

## x = right, y = forward, in camera space. Length 0..1.
var move := Vector2.ZERO
var jump_pressed := false
var jump_held := false
var sprint := false
var parkour := false
