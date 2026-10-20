class_name TraversalMetrics
extends Resource
## The movement contract. Level geometry is built to these numbers
## (docs/ASSET_GUIDE.md), so change them deliberately and log it.

@export_group("Body")
@export var height := 1.75
@export var radius := 0.3
@export var step_height := 0.35

@export_group("Ground speed (m/s)")
@export var walk_speed := 2.0
@export var jog_speed := 5.0
@export var sprint_speed := 8.0
@export var ground_accel := 28.0
@export var ground_decel := 36.0
## Turn rate (rad/s) at jog; drops toward sprint so fast running carries momentum.
@export var turn_rate := 14.0
@export var sprint_turn_rate := 6.0

@export_group("Air")
@export var gravity := 22.0
@export var fall_gravity_mult := 1.6
@export var jump_height := 1.2
## Vertical velocity is multiplied by this when jump is released early.
@export var jump_cut := 0.45
@export var air_accel := 9.0
@export var max_fall_speed := 40.0
@export var coyote_time := 0.12
@export var jump_buffer_time := 0.15

@export_group("Landing")
## Downward speed (m/s) above which a landing becomes a hard landing.
@export var hard_landing_speed := 13.0
@export var hard_landing_time := 0.3
@export var hard_landing_speed_keep := 0.35

@export_group("Vault / Climb (heights above feet, m)")
@export var vault_min := 0.4
@export var vault_max := 1.15
## Obstacles thinner than this are vaulted over; deeper ones are stepped onto.
@export var vault_max_depth := 1.2
@export var climb_max := 2.3
## Mid-air grabs reach less above the feet (hands are already up at the apex),
## so a running jump reaches ~jump_height + this.
@export var air_climb_max := 1.4
## How far ahead (m) the traversal probe looks, plus a speed-based bonus.
@export var probe_reach := 0.7
@export var probe_reach_per_speed := 0.06
@export var vault_time := 0.38
@export var climb_time_per_meter := 0.22
## Auto-vault low obstacles when running at least this fast (no button needed).
@export var auto_vault_speed := 6.5


func jump_velocity() -> float:
	return sqrt(2.0 * gravity * jump_height)
