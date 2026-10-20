extends CanvasLayer
## F3 / Back toggles a readout of the movement state for tuning.

@export var player: Player

@onready var label: Label = $Label


func _process(_delta: float) -> void:
	if Input.is_action_just_pressed(&"toggle_debug"):
		visible = not visible
	if not visible or not player:
		return
	label.text = "FPS %d\nstate  %s\nspeed  %.2f m/s\nvert   %.2f m/s\nfloor  %s\npos    %s" % [
		Engine.get_frames_per_second(),
		player.machine.state_name(),
		player.horizontal_speed(),
		player.velocity.y,
		player.is_on_floor(),
		"(%.1f, %.1f, %.1f)" % [player.global_position.x, player.global_position.y, player.global_position.z],
	]
