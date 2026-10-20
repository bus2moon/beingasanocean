extends AirState


func physics_update(delta: float) -> void:
	if player.coyote_open and machine.time_in_state > player.metrics.coyote_time:
		player.coyote_open = false
	if player.coyote_open and player.buffer.consume(&"jump", player.metrics.jump_buffer_time):
		machine.transition(&"Jump")
		return
	air_tick(delta)
