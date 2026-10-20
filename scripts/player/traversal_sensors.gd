class_name TraversalSensors
extends RefCounted
## Physics queries that answer "what can I do with the thing in front of me?"
## Pure queries: no state, no side effects, so states can probe freely.

enum Kind { NONE, VAULT, STEP_UP, CLIMB }

const WORLD_MASK := 1
const WALL_MAX_NORMAL_Y := 0.35
const FLOOR_MIN_NORMAL_Y := 0.7


class Ledge:
	var kind := Kind.NONE
	## Height of the obstacle top above the feet when probed.
	var height := 0.0
	## Where the wall was hit, and its horizontal normal (points at the player).
	var wall_point := Vector3.ZERO
	var wall_normal := Vector3.ZERO
	## Where the feet end up: on top (STEP_UP / CLIMB) or past it (VAULT).
	var end_point := Vector3.ZERO
	## Top of the obstacle at its near edge; vault arcs pass over this.
	var edge_point := Vector3.ZERO


var _body: CharacterBody3D
var _m: TraversalMetrics
var _stand_shape: CapsuleShape3D


func _init(body: CharacterBody3D, metrics: TraversalMetrics) -> void:
	_body = body
	_m = metrics
	_stand_shape = CapsuleShape3D.new()
	_stand_shape.radius = metrics.radius
	_stand_shape.height = metrics.height


## Probe along `forward` (horizontal, normalised) from `feet`. Returns null if
## nothing traversable is there.
func probe(feet: Vector3, forward: Vector3, speed: float, airborne: bool) -> Ledge:
	var space := _body.get_world_3d().direct_space_state
	var reach := _m.radius + _m.probe_reach + speed * _m.probe_reach_per_speed
	var max_height := _m.air_climb_max if airborne else _m.climb_max

	# 1. Find a wall facing us.
	var ray_heights := [0.45, 0.9, 1.4, 1.9]
	if airborne:
		ray_heights.push_front(0.1)
	var wall := {}
	for h: float in ray_heights:
		if h > max_height:
			break
		var from := feet + Vector3.UP * h
		var hit := _ray(space, from, from + forward * reach)
		if hit.is_empty():
			continue
		var n: Vector3 = hit.normal
		if absf(n.y) > WALL_MAX_NORMAL_Y:
			continue
		var n_flat := Vector3(n.x, 0.0, n.z).normalized()
		if forward.dot(-n_flat) < 0.5:
			continue
		wall = hit
		wall.normal = n_flat
		break
	if wall.is_empty():
		return null

	var inward: Vector3 = -wall.normal
	var wall_point: Vector3 = wall.position

	# 2. Too tall to reach? Anything solid just above max climb height means no.
	var over := feet + Vector3.UP * (max_height + 0.15)
	if not _ray(space, over, over + forward * (reach + 0.3)).is_empty():
		return null

	# 3. Find the top surface just inside the edge.
	var edge_xz := Vector3(wall_point.x, 0.0, wall_point.z) + inward * 0.15
	var top_hit := _ray(space,
		Vector3(edge_xz.x, feet.y + max_height + 0.1, edge_xz.z),
		Vector3(edge_xz.x, feet.y + 0.05, edge_xz.z))
	if top_hit.is_empty() or top_hit.normal.y < FLOOR_MIN_NORMAL_Y:
		return null
	var top_y: float = top_hit.position.y
	var height := top_y - feet.y
	var min_height := 0.05 if airborne else _m.vault_min
	if height < min_height:
		return null

	var ledge := Ledge.new()
	ledge.height = height
	ledge.wall_point = wall_point
	ledge.wall_normal = wall.normal
	ledge.edge_point = Vector3(wall_point.x, top_y, wall_point.z)

	# 4. Thin (vault over) or deep (step / climb onto)?
	var depth := _top_depth(space, wall_point, inward, top_y)
	var deep := depth >= _m.vault_max_depth
	if deep or airborne:
		var stand := Vector3(wall_point.x, top_y, wall_point.z) + inward * (_m.radius + 0.2)
		if not _fits(space, stand) or (airborne and depth < _m.radius * 2.0 + 0.2):
			return null
		ledge.end_point = stand
		ledge.kind = Kind.STEP_UP if height <= _m.vault_max and not airborne else Kind.CLIMB
		return ledge

	if height > _m.vault_max:
		return null # tall thin wall: wall-top balance is a Phase 2 move
	var land_xz := wall_point + inward * (depth + _m.radius + 0.35)
	var ground := _ray(space,
		Vector3(land_xz.x, top_y + 0.2, land_xz.z),
		Vector3(land_xz.x, feet.y - 3.0, land_xz.z))
	var land_y: float = ground.position.y if not ground.is_empty() else feet.y
	var land := Vector3(land_xz.x, land_y, land_xz.z)
	if not _fits(space, land):
		return null
	ledge.end_point = land
	ledge.kind = Kind.VAULT
	return ledge


## How far the top surface continues past the edge (capped at vault_max_depth).
func _top_depth(space: PhysicsDirectSpaceState3D, wall_point: Vector3, inward: Vector3, top_y: float) -> float:
	var d := 0.15
	while d < _m.vault_max_depth:
		var p := wall_point + inward * d
		var hit := _ray(space, Vector3(p.x, top_y + 0.2, p.z), Vector3(p.x, top_y - 0.25, p.z))
		if hit.is_empty():
			return d
		d += 0.15
	return _m.vault_max_depth


## Would a standing capsule with its feet at `feet` overlap world geometry?
func _fits(space: PhysicsDirectSpaceState3D, feet: Vector3) -> bool:
	var q := PhysicsShapeQueryParameters3D.new()
	q.shape = _stand_shape
	q.collision_mask = WORLD_MASK
	q.exclude = [_body.get_rid()]
	q.transform = Transform3D(Basis.IDENTITY, feet + Vector3.UP * (_m.height * 0.5 + 0.05))
	return space.intersect_shape(q, 1).is_empty()


func _ray(space: PhysicsDirectSpaceState3D, from: Vector3, to: Vector3) -> Dictionary:
	var q := PhysicsRayQueryParameters3D.create(from, to, WORLD_MASK, [_body.get_rid()])
	return space.intersect_ray(q)
