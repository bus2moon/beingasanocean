extends GroundState


func physics_update(delta: float) -> void:
	if ground_tick(delta):
		return
	if player.intent.move.length() > 0.1:
		machine.transition(&"Move")
