class_name Player
extends CharacterBody3D
## Cub. Owns the motor helpers (speed, gravity, facing) and the shared pieces
## states need: intent, input buffer, traversal sensors. Movement decisions
## live in the states under $StateMachine.

signal state_changed(from: StringName, to: StringName)

@export var metrics: TraversalMetrics = TraversalMetrics.new()
## Rig whose `yaw` makes stick/WASD input camera-relative. Optional.
@export var camera_rig: Node3D

## When set, movement reads this instead of devices (tests, cutscenes, AI).
var scripted_intent: PlayerIntent
var intent := PlayerIntent.new()
var buffer := InputBuffer.new()
var sensors: TraversalSensors
## Horizontal unit vector the body faces.
var facing := Vector3.FORWARD
## Ledge chosen by a state, consumed by Vault / Climb on enter.
var pending_ledge: TraversalSensors.Ledge
## True after walking off an edge, until coyote time runs out or we jump.
var coyote_open := false
## Downward speed at the moment of the last landing (positive number).
var last_impact_speed := 0.0

@onready var machine: StateMachine = $StateMachine
@onready var visual: Node3D = $Visual


func _ready() -> void:
	sensors = TraversalSensors.new(self, metrics)
	floor_snap_length = 0.3
	floor_max_angle = deg_to_rad(46.0)
	machine.state_changed.connect(func(f: StringName, t: StringName) -> void: state_changed.emit(f, t))
	machine.setup(self)


func _physics_process(delta: float) -> void:
	intent = scripted_intent if scripted_intent else _read_devices()
	buffer.tick(delta)
	if intent.jump_pressed:
		buffer.press(&"jump")
	machine.physics_update(delta)
	visual.global_basis = Basis.looking_at(facing, Vector3.UP)


func _read_devices() -> PlayerIntent:
	var i := PlayerIntent.new()
	i.move = Input.get_vector(&"move_left", &"move_right", &"move_back", &"move_forward")
	i.jump_pressed = Input.is_action_just_pressed(&"jump")
	i.jump_held = Input.is_action_pressed(&"jump")
	i.sprint = Input.is_action_pressed(&"sprint")
	i.parkour = Input.is_action_pressed(&"parkour")
	return i


# --- queries ---------------------------------------------------------------

## Desired move direction in world space, length 0..1.
func wish_direction() -> Vector3:
	var yaw: float = camera_rig.yaw if camera_rig else 0.0
	var right := Vector3(cos(yaw), 0.0, -sin(yaw))
	var forward := Vector3(-sin(yaw), 0.0, -cos(yaw))
	return right * intent.move.x + forward * intent.move.y


func horizontal_velocity() -> Vector3:
	return Vector3(velocity.x, 0.0, velocity.z)


func horizontal_speed() -> float:
	return horizontal_velocity().length()


## Look for a vault / climb in the direction we want to go (or face).
func probe_ledge() -> TraversalSensors.Ledge:
	var dir := wish_direction()
	dir = dir.normalized() if dir.length() > 0.2 else facing
	return sensors.probe(global_position, dir, horizontal_speed(), not is_on_floor())


# --- motor -----------------------------------------------------------------

func target_ground_speed() -> float:
	var amount := intent.move.length()
	if amount < 0.1:
		return 0.0
	if intent.sprint:
		return metrics.sprint_speed
	# Analog sticks walk on a light push and jog on a full one.
	if amount < 0.6:
		return lerpf(metrics.walk_speed, metrics.jog_speed, inverse_lerp(0.1, 0.6, amount))
	return metrics.jog_speed


func ground_move(delta: float) -> void:
	var wish := wish_direction()
	var h := horizontal_velocity()
	var speed := h.length()
	var target := target_ground_speed()
	if wish.length() < 0.1:
		speed = move_toward(speed, 0.0, metrics.ground_decel * delta)
		h = h.normalized() * speed if speed > 0.0 else Vector3.ZERO
	else:
		var wish_dir := wish.normalized()
		var dir := h.normalized() if speed > 0.5 else wish_dir
		var angle := dir.signed_angle_to(wish_dir, Vector3.UP)
		if absf(angle) > deg_to_rad(150.0) and speed > metrics.jog_speed * 0.5:
			# Hard reversal at speed: skid down before turning.
			speed = move_toward(speed, 0.0, metrics.ground_decel * delta)
		else:
			var t := clampf(inverse_lerp(metrics.jog_speed, metrics.sprint_speed, speed), 0.0, 1.0)
			var rate := lerpf(metrics.turn_rate, metrics.sprint_turn_rate, t)
			dir = dir.rotated(Vector3.UP, clampf(angle, -rate * delta, rate * delta))
			var accel := metrics.ground_accel if target >= speed else metrics.ground_decel
			speed = move_toward(speed, target, accel * delta)
		h = dir * speed
	velocity.x = h.x
	velocity.z = h.z


func air_move(delta: float) -> void:
	var h := horizontal_velocity()
	var cap := maxf(h.length(), metrics.jog_speed)
	h += wish_direction() * metrics.air_accel * delta
	h = h.limit_length(cap)
	velocity.x = h.x
	velocity.z = h.z


func apply_gravity(delta: float) -> void:
	var g := metrics.gravity * (metrics.fall_gravity_mult if velocity.y < 0.0 else 1.0)
	velocity.y = maxf(velocity.y - g * delta, -metrics.max_fall_speed)


func face_movement(delta: float, rate := 12.0) -> void:
	var h := horizontal_velocity()
	if h.length() > 0.3:
		face_toward(h, delta, rate)


func face_toward(dir: Vector3, delta: float, rate := 12.0) -> void:
	dir.y = 0.0
	if dir.length() < 0.001:
		return
	dir = dir.normalized()
	var angle := facing.signed_angle_to(dir, Vector3.UP)
	facing = facing.rotated(Vector3.UP, clampf(angle, -rate * delta, rate * delta)).normalized()


## Start the right traversal state for `ledge`.
func begin_traversal(ledge: TraversalSensors.Ledge) -> void:
	pending_ledge = ledge
	coyote_open = false
	machine.transition(&"Climb" if ledge.kind == TraversalSensors.Kind.CLIMB else &"Vault")
