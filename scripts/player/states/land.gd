extends PlayerState
## Hard landing: brief recovery that bleeds speed. Soft landings skip this.
## (Phase 2 adds a timed roll that cancels it.)


func enter(_from: StringName) -> void:
	var keep := player.metrics.hard_landing_speed_keep
	player.velocity.x *= keep
	player.velocity.z *= keep


func physics_update(delta: float) -> void:
	var h := player.horizontal_velocity()
	h = h.move_toward(Vector3.ZERO, player.metrics.ground_decel * 0.5 * delta)
	player.velocity = Vector3(h.x, player.velocity.y, h.z)
	player.apply_gravity(delta)
	player.move_and_slide()
	if machine.time_in_state >= player.metrics.hard_landing_time:
		machine.transition(&"Move" if player.intent.move.length() > 0.1 else &"Idle")
