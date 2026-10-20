class_name GroundState
extends PlayerState
## Shared ground logic for Idle and Move. Returns true from ground_tick when it
## already transitioned, so the subclass stops.


func ground_tick(delta: float) -> bool:
	player.ground_move(delta)
	player.move_and_slide()
	player.face_movement(delta)

	if not player.is_on_floor():
		player.coyote_open = true
		machine.transition(&"Fall")
		return true

	if player.buffer.consume(&"jump", player.metrics.jump_buffer_time):
		var ledge := player.probe_ledge()
		if ledge:
			player.begin_traversal(ledge)
		else:
			machine.transition(&"Jump")
		return true

	# Running fast into something low: flow over it without a button.
	if player.horizontal_speed() >= player.metrics.auto_vault_speed:
		var ledge := player.probe_ledge()
		if ledge and ledge.kind != TraversalSensors.Kind.CLIMB:
			player.begin_traversal(ledge)
			return true
	return false
