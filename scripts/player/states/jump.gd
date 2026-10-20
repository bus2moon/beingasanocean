extends AirState

var _cut := false


func enter(_from: StringName) -> void:
	_cut = false
	player.coyote_open = false
	player.velocity.y = player.metrics.jump_velocity()


func physics_update(delta: float) -> void:
	# Variable height: letting go early cuts the rise.
	if not _cut and not player.intent.jump_held and player.velocity.y > 0.0:
		player.velocity.y *= player.metrics.jump_cut
		_cut = true
	if air_tick(delta):
		return
	if player.velocity.y <= 0.0:
		machine.transition(&"Fall")
