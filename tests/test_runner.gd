extends Node
## Headless movement tests. Run with tools/run_tests.sh (exit code 0 = pass).
## Each test builds a tiny arena, drives Cub through PlayerIntent, steps real
## physics frames, and checks where he ended up and which states he went
## through. These prove behaviour, not feel: feel is checked by playing.

const PLAYER_SCENE := preload("res://scenes/player/player.tscn")
const LEVEL_SCENE := preload("res://scenes/levels/graybox_block.tscn")

var _failures: Array[String] = []
var _checks := 0
var _world: Node3D
var _player: Player
var _intent: PlayerIntent
var _history: Array[StringName] = []


func _ready() -> void:
	var tests := [
		test_idle_settles, test_jog_speed, test_sprint_speed,
		test_full_jump_height, test_short_hop, test_jump_buffer,
		test_coyote_jump, test_late_jump_after_edge_fails,
		test_vault_thin_wall, test_auto_vault_at_sprint, test_step_up_low_block,
		test_climb_2m_block, test_too_tall_wall_no_climb, test_air_ledge_grab,
		test_hard_landing, test_soft_landing, test_graybox_level,
		test_animation_follows_state,
	]
	for t: Callable in tests:
		await _run(t)
	print("\n%d checks, %d failures" % [_checks, _failures.size()])
	for f in _failures:
		print("  FAIL ", f)
	get_tree().quit(1 if _failures.size() > 0 else 0)


func _run(t: Callable) -> void:
	var before := _failures.size()
	await t.call()
	print("%s %s" % ["PASS" if _failures.size() == before else "FAIL", t.get_method()])
	if _world:
		_world.queue_free()
		_world = null
		await get_tree().process_frame


# --- arena helpers -----------------------------------------------------------

func _arena(boxes: Array = []) -> void:
	_world = Node3D.new()
	add_child(_world)
	_box(Vector3(0, -0.5, 0), Vector3(100, 1, 100))
	for b: Array in boxes:
		_box(b[0], b[1])


## Box by centre and size.
func _box(center: Vector3, size: Vector3) -> void:
	var body := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	shape.shape = BoxShape3D.new()
	shape.shape.size = size
	body.add_child(shape)
	_world.add_child(body)
	body.global_position = center


## Box by footprint: x, z centre, bottom y, width, height, depth.
func _block(x: float, z: float, w: float, h: float, d: float, y := 0.0) -> Array:
	return [Vector3(x, y + h / 2.0, z), Vector3(w, h, d)]


func _spawn(pos: Vector3) -> void:
	_player = PLAYER_SCENE.instantiate()
	_intent = PlayerIntent.new()
	_player.scripted_intent = _intent
	_history.clear()
	_world.add_child(_player)
	_player.global_position = pos
	_player.state_changed.connect(func(_f: StringName, t: StringName) -> void: _history.append(t))
	await _frames(20)


func _frames(n: int) -> void:
	for i in n:
		await get_tree().physics_frame


func _press_jump() -> void:
	_intent.jump_pressed = true
	_intent.jump_held = true
	await get_tree().physics_frame
	_intent.jump_pressed = false


## Step until `cond` is true or `max_frames` pass. Returns whether it became true.
func _until(cond: Callable, max_frames := 300) -> bool:
	for i in max_frames:
		if cond.call():
			return true
		await get_tree().physics_frame
	return cond.call()


func _check(ok: bool, what: String) -> void:
	_checks += 1
	if not ok:
		_failures.append(what)
		print("    x ", what)


func _near(a: float, b: float, tol: float, what: String) -> void:
	_check(absf(a - b) <= tol, "%s: got %.3f, want %.3f +/- %.2f" % [what, a, b, tol])


# --- tests -------------------------------------------------------------------

func test_idle_settles() -> void:
	_arena()
	await _spawn(Vector3(0, 0.5, 0))
	await _frames(30)
	_check(_player.is_on_floor(), "on floor after settling")
	_check(_player.machine.state_name() == &"Idle", "idle when settled, got %s" % _player.machine.state_name())
	_near(_player.global_position.y, 0.0, 0.05, "feet on ground")


func test_jog_speed() -> void:
	_arena()
	await _spawn(Vector3.ZERO)
	_intent.move = Vector2(0, 1)
	await _frames(60)
	_near(_player.horizontal_speed(), _player.metrics.jog_speed, 0.2, "jog speed")
	_check(_player.machine.state_name() == &"Move", "state Move")
	_check(_player.velocity.z < 0.0, "camera-forward is -Z")


func test_sprint_speed() -> void:
	_arena()
	await _spawn(Vector3.ZERO)
	_intent.move = Vector2(0, 1)
	_intent.sprint = true
	await _frames(90)
	_near(_player.horizontal_speed(), _player.metrics.sprint_speed, 0.2, "sprint speed")


func _measure_apex(release_after: int) -> float:
	var start_y := _player.global_position.y
	var apex := start_y
	_intent.jump_pressed = true
	_intent.jump_held = true
	for i in 90:
		await get_tree().physics_frame
		_intent.jump_pressed = false
		if i >= release_after:
			_intent.jump_held = false
		apex = maxf(apex, _player.global_position.y)
	return apex - start_y


func test_full_jump_height() -> void:
	_arena()
	await _spawn(Vector3.ZERO)
	var h := await _measure_apex(999)
	_near(h, _player.metrics.jump_height, 0.08, "full jump apex")
	_check(_history.has(&"Jump") and _history.has(&"Fall"), "went Jump -> Fall, got %s" % [_history])
	_check(_player.is_on_floor(), "landed again")


func test_short_hop() -> void:
	_arena()
	await _spawn(Vector3.ZERO)
	var h := await _measure_apex(1)
	_check(h < _player.metrics.jump_height * 0.6, "tap jump is lower: %.2f" % h)
	_check(h > 0.15, "tap jump still leaves the ground: %.2f" % h)


func test_jump_buffer() -> void:
	_arena()
	await _spawn(Vector3.ZERO)
	_player.global_position = Vector3(0, 1.8, 0)
	await _until(func() -> bool: return _player.velocity.y < -1.0 and _player.global_position.y < 0.5)
	_history.clear()
	await _press_jump()
	_check(not _player.is_on_floor(), "pressed while still airborne")
	await _until(func() -> bool: return _history.has(&"Jump"), 30)
	_check(_history.has(&"Jump"), "buffered press jumps on landing, got %s" % [_history])


func test_coyote_jump() -> void:
	_arena([_block(0, -1, 3, 1, 4)])
	await _spawn(Vector3(0, 1.1, 0))
	_intent.move = Vector2(0, 1)
	await _until(func() -> bool: return _player.machine.state_name() == &"Fall")
	await _frames(3)
	_history.clear()
	await _press_jump()
	_check(_history.has(&"Jump"), "jump within coyote time, got %s" % [_history])


func test_late_jump_after_edge_fails() -> void:
	_arena([_block(0, -1, 3, 4, 4)])
	await _spawn(Vector3(0, 4.1, 0))
	_intent.move = Vector2(0, 1)
	await _until(func() -> bool: return _player.machine.state_name() == &"Fall")
	await _frames(20)
	_history.clear()
	await _press_jump()
	_check(not _history.has(&"Jump"), "no jump 0.33 s after leaving edge, got %s" % [_history])


func test_vault_thin_wall() -> void:
	_arena([_block(0, -4, 3, 1.0, 0.3)])
	await _spawn(Vector3.ZERO)
	_intent.move = Vector2(0, 1)
	await _until(func() -> bool: return _player.global_position.z < -2.7)
	await _press_jump()
	await _frames(40)
	_check(_history.has(&"Vault"), "vaulted, got %s" % [_history])
	_check(_player.global_position.z < -4.5, "ended past the wall, z=%.2f" % _player.global_position.z)
	_check(_player.horizontal_speed() > 4.0, "kept speed: %.2f" % _player.horizontal_speed())
	_check(_player.is_on_floor(), "back on the floor")


func test_auto_vault_at_sprint() -> void:
	_arena([_block(0, -10, 3, 0.8, 0.3)])
	await _spawn(Vector3.ZERO)
	_intent.move = Vector2(0, 1)
	_intent.sprint = true
	await _until(func() -> bool: return _player.global_position.z < -12.0, 200)
	_check(_history.has(&"Vault"), "sprinted over without a button, got %s" % [_history])
	_check(not _history.has(&"Jump"), "no jump involved")


func test_step_up_low_block() -> void:
	_arena([_block(0, -5, 3, 1.0, 3)])
	await _spawn(Vector3.ZERO)
	_intent.move = Vector2(0, 1)
	await _until(func() -> bool: return _player.global_position.z < -2.4)
	await _press_jump()
	await _frames(40)
	_check(_history.has(&"Vault"), "step-vaulted, got %s" % [_history])
	_near(_player.global_position.y, 1.0, 0.06, "standing on 1 m block")


func test_climb_2m_block() -> void:
	_arena([_block(0, -3, 3, 2.0, 3)])
	await _spawn(Vector3.ZERO)
	_intent.move = Vector2(0, 1)
	await _frames(10)
	await _press_jump()
	await _frames(60)
	_check(_history.has(&"Climb"), "climbed, got %s" % [_history])
	_near(_player.global_position.y, 2.0, 0.06, "standing on 2 m block")


func test_too_tall_wall_no_climb() -> void:
	_arena([_block(0, -3, 3, 2.8, 3)])
	await _spawn(Vector3.ZERO)
	_intent.move = Vector2(0, 1)
	await _frames(10)
	await _press_jump()
	await _frames(60)
	_check(not _history.has(&"Climb"), "2.8 m wall is out of reach, got %s" % [_history])
	_check(_player.global_position.y < 0.1, "still on the ground")


func test_air_ledge_grab() -> void:
	# Run off a 1.5 m platform, jump a 3 m gap at a ledge 1.5 m higher.
	_arena([_block(0, -6, 3, 1.5, 12), _block(0, -21, 3, 3.0, 12)])
	await _spawn(Vector3(0, 1.6, -1))
	_intent.move = Vector2(0, 1)
	_intent.sprint = true
	await _until(func() -> bool: return _player.global_position.z < -11.6)
	await _press_jump()
	await _frames(90)
	_check(_history.has(&"Climb"), "grabbed the ledge mid-air, got %s" % [_history])
	_near(_player.global_position.y, 3.0, 0.06, "on top of the far ledge")


func test_hard_landing() -> void:
	_arena()
	await _spawn(Vector3.ZERO)
	_player.global_position = Vector3(0, 8, 0)
	await _until(func() -> bool: return _player.is_on_floor() and _history.size() > 0, 200)
	_check(_history.has(&"Land"), "8 m drop is a hard landing, got %s" % [_history])


func test_soft_landing() -> void:
	_arena()
	await _spawn(Vector3.ZERO)
	_player.global_position = Vector3(0, 1.5, 0)
	await _frames(60)
	_check(not _history.has(&"Land"), "1.5 m drop is soft, got %s" % [_history])


func test_graybox_level() -> void:
	_world = Node3D.new()
	add_child(_world)
	var level := LEVEL_SCENE.instantiate()
	_world.add_child(level)
	var bodies := level.find_children("*", "StaticBody3D", true, false)
	_check(bodies.size() >= 25, "level has collision bodies: %d" % bodies.size())
	# Climb the real 2 m block in Lane B (spans z -20.5..-23.5 at x=-6).
	await _spawn(Vector3(-6, 0.1, -18.6))
	_near(_player.global_position.y, 0.0, 0.05, "standing on level ground")
	_intent.move = Vector2(0, 1)
	await _frames(10)
	await _press_jump()
	await _frames(60)
	_check(_history.has(&"Climb"), "climbed level block, got %s" % [_history])
	_near(_player.global_position.y, 2.0, 0.06, "on top of ClimbBlock_200")


func test_animation_follows_state() -> void:
	_arena()
	await _spawn(Vector3.ZERO)
	var anim: AnimationPlayer = _player.get_node("AnimationController").anim
	_check(anim.current_animation == &"Idle", "idle clip, got %s" % anim.current_animation)
	_intent.move = Vector2(0, 1)
	await _frames(40)
	_check(anim.current_animation == &"Jog_Fwd", "jog clip, got %s" % anim.current_animation)
	_intent.sprint = true
	await _frames(40)
	_check(anim.current_animation == &"Sprint", "sprint clip, got %s" % anim.current_animation)
	await _press_jump()
	await _frames(3)
	_check(anim.current_animation == &"Jump", "air clip, got %s" % anim.current_animation)
