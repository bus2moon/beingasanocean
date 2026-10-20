class_name AirState
extends PlayerState
## Shared airborne logic for Jump and Fall: steering, gravity, ledge grabs,
## and choosing a landing.


func air_tick(delta: float) -> bool:
	player.air_move(delta)
	player.apply_gravity(delta)
	var falling_speed := -player.velocity.y
	player.move_and_slide()
	player.face_movement(delta, 6.0)

	if player.is_on_floor():
		player.last_impact_speed = falling_speed
		if falling_speed >= player.metrics.hard_landing_speed:
			machine.transition(&"Land")
		elif player.intent.move.length() > 0.1 or player.horizontal_speed() > 0.1:
			machine.transition(&"Move")
		else:
			machine.transition(&"Idle")
		return true

	# Grab a ledge we're heading into.
	var heading := player.horizontal_velocity()
	if heading.length() > 0.5 or player.intent.move.length() > 0.3:
		var ledge := player.probe_ledge()
		if ledge and ledge.kind == TraversalSensors.Kind.CLIMB:
			player.begin_traversal(ledge)
			return true
	return false
