class_name CameraRig
extends Node3D
## Third-person orbit camera tuned for fast traversal: smoothed follow, wall
## collision via SpringArm3D, speed-based FOV, and gentle auto-recentre behind
## the direction of travel when the player isn't steering the camera.

@export var target: Player
@export var pivot_height := 1.55
@export var arm_length := 3.6
@export var min_pitch := deg_to_rad(-65.0)
@export var max_pitch := deg_to_rad(40.0)
@export var follow_sharpness := 18.0
@export var vertical_sharpness := 7.0
@export var base_fov := 70.0
@export var sprint_fov_bonus := 9.0
@export var recenter_delay := 1.2
@export var recenter_rate := 1.6

var yaw := 0.0
var pitch := deg_to_rad(-12.0)
var _idle_look_time := 0.0

@onready var arm: SpringArm3D = $SpringArm3D
@onready var camera: Camera3D = $SpringArm3D/Camera3D


func _ready() -> void:
	top_level = true
	arm.spring_length = arm_length
	if target:
		arm.add_excluded_object(target.get_rid())
		global_position = target.global_position + Vector3.UP * pivot_height


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		var s: float = Settings.mouse_sensitivity
		_look(-event.relative.x * s, -event.relative.y * s * (-1.0 if Settings.invert_y else 1.0))


func _physics_process(delta: float) -> void:
	if not target:
		return
	var stick := Input.get_vector(&"look_left", &"look_right", &"look_up", &"look_down")
	if stick.length() > 0.0:
		var s: float = Settings.stick_sensitivity * delta
		_look(-stick.x * s, -stick.y * s * (-1.0 if Settings.invert_y else 1.0))
	else:
		_idle_look_time += delta
	_follow(delta)
	_recenter(delta)
	var speed := target.horizontal_speed()
	var m := target.metrics
	var t := clampf(inverse_lerp(m.jog_speed, m.sprint_speed, speed), 0.0, 1.0)
	camera.fov = lerpf(camera.fov, base_fov + sprint_fov_bonus * t, 1.0 - exp(-4.0 * delta))
	rotation = Vector3(pitch, yaw, 0.0)


func _look(d_yaw: float, d_pitch: float) -> void:
	yaw = wrapf(yaw + d_yaw, -PI, PI)
	pitch = clampf(pitch + d_pitch, min_pitch, max_pitch)
	_idle_look_time = 0.0


func _follow(delta: float) -> void:
	var goal := target.global_position + Vector3.UP * pivot_height
	var p := global_position
	var hk := 1.0 - exp(-follow_sharpness * delta)
	var vk := 1.0 - exp(-vertical_sharpness * delta)
	global_position = Vector3(lerpf(p.x, goal.x, hk), lerpf(p.y, goal.y, vk), lerpf(p.z, goal.z, hk))


func _recenter(delta: float) -> void:
	if _idle_look_time < recenter_delay or target.horizontal_speed() < 3.0:
		return
	# Only follow while pushing mostly forward; recentring during a sideways
	# hold bends the camera-relative input and spirals the player.
	if absf(target.intent.move.x) > 0.3:
		return
	var v := target.horizontal_velocity()
	var goal_yaw := atan2(-v.x, -v.z)
	yaw = lerp_angle(yaw, goal_yaw, 1.0 - exp(-recenter_rate * delta))
