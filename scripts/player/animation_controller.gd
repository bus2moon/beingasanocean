class_name AnimationController
extends Node
## Picks and blends the model's animations from the movement state and speed.
## Reads the Player; never moves it (TECH_ARCHITECTURE.md: code drives
## movement, animation follows).

## state -> clip. Vault / Climb use the air loop until parkour clips exist
## (Quaternius UAL 2 or our own Blender clips — see BACKLOG.md).
const STATE_CLIPS := {
	&"Idle": &"Idle",
	&"Jump": &"Jump",
	&"Fall": &"Jump",
	&"Land": &"Jump_Land",
	&"Vault": &"Jump",
	&"Climb": &"Jump",
}
## Locomotion clips with the ground speed (m/s) each one looks right at.
const GAITS := [
	[&"Walk", 1.6],
	[&"Jog_Fwd", 4.5],
	[&"Sprint", 7.5],
]
const BLEND := 0.12

@export var player: Player
@export var model: Node3D

var anim: AnimationPlayer


func _ready() -> void:
	anim = model.find_children("*", "AnimationPlayer", true, false)[0]
	anim.play(&"Idle")


func _physics_process(_delta: float) -> void:
	var state := player.machine.state_name()
	var clip: StringName
	var scale := 1.0
	if state == &"Move":
		var speed := player.horizontal_speed()
		var gait: Array = _gait_for(speed)
		clip = gait[0]
		scale = clampf(speed / gait[1], 0.6, 1.4) if speed > 0.3 else 1.0
		if speed < 0.3:
			clip = &"Idle"
	else:
		clip = STATE_CLIPS.get(state, &"Idle")
	if anim.current_animation != clip:
		anim.play(clip, BLEND)
	anim.speed_scale = scale


func _gait_for(speed: float) -> Array:
	# Switch at the midpoint between neighbouring gaits' natural speeds.
	for i in GAITS.size() - 1:
		if speed < (GAITS[i][1] + GAITS[i + 1][1]) * 0.5:
			return GAITS[i]
	return GAITS[-1]
