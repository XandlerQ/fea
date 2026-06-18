extends Node
## Defines projectile movement behavior.
class_name ProjectileMovementComponent

#region Signals

#endregion

#region Exports
@export_group("References")
## Controlled projectile reference
@export var projectile: Projectile = null

## Projectile linear speed
@export var projectileSpeed: float = 20
## Projectile gravity
@export var gravity: float = 10

#endregion

#region State
## Desired velocity
var desiredVelocity: Vector3 = Vector3.ZERO
## Launch direction
var launchDirection: Vector3 = Vector3.FORWARD

## Previous position
var previousPosition: Vector3 = Vector3.ZERO

## Launched flag
var launched: bool = false
#endregion

#region Methods
#region System
func _ready() -> void:
	pass

func _physics_process(delta: float) -> void:
	if not launched:
		return

	# Compute the desired velocity
	desiredVelocity += delta * gravity * Vector3.DOWN
	# Compute the desired motion
	var desiredMotion: Vector3 = delta * desiredVelocity
	var safeMotion: Vector3 = desiredMotion

	# Handle tunneling
	if projectile.cdm != projectile.ColDetMethod.Hitbox:
		var collisionResult: Dictionary = _handle_tunneling(delta)

		if not collisionResult.is_empty():
			var safeFraction: float = collisionResult.get("safe_fraction", 0.0)
			var hits: Array = collisionResult.get("hits", [])
			
			safeMotion = safeFraction * desiredMotion

			for hit in hits:
				projectile.handle_hit(hit)


	# Do the update
	# Store previous position
	previousPosition = projectile.position
	# Update the position
	# TODO: implement a version for the projectiles that pierce
	if true:
		projectile.position += desiredMotion
	else:
		projectile.position += safeMotion

#endregion

#region Interface
func launch(direction: Vector3, initialVelocity: Vector3 = Vector3.ZERO) -> void:
	# Save launch direction
	launchDirection = direction
	
	# Compute the initial velocity
	desiredVelocity = initialVelocity + projectileSpeed * launchDirection

	# Switch the launch flag
	launched = true
#endregion

#region Private
func _handle_tunneling(delta: float) -> Dictionary:
	if projectile.cdm == projectile.ColDetMethod.Hitbox:
		return {}

	elif projectile.cdm == projectile.ColDetMethod.Raycast:
		# Get current position
		var from: Vector3 = projectile.position
		# Compute the next position
		var to: Vector3 = from + delta * desiredVelocity

		# Compute a path
		var path: Vector3 = to - from
		var path_len: float = path.length()
		var safe_fraction: float = 0.0

		# Create the query
		var query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(from, to)
		query.collide_with_areas = true
		query.collide_with_bodies = true

		if projectile.hitbox:
			query.exclude.append(projectile.hitbox.get_rid())

		var spaceState: PhysicsDirectSpaceState3D= projectile.get_world_3d().direct_space_state
		var hit: Dictionary = spaceState.intersect_ray(query)

		if hit.is_empty():
			return {}

		if path_len > 1e-6:
			safe_fraction = from.distance_to(hit.position) / path_len

		return {
			"safe_fraction": safe_fraction,
			"unsafe_fraction": safe_fraction,
			"transform": Transform3D(Basis.IDENTITY, hit.position),
			"hits": [hit],
		}
		
	elif projectile.cdm == projectile.ColDetMethod.Sweep:
		if not projectile.effectiveColShape:
			return {}
		if not projectile.effectiveColShape.shape:
			return {}

		var motion: Vector3 = delta * desiredVelocity

		var query: PhysicsShapeQueryParameters3D = PhysicsShapeQueryParameters3D.new()
		query.shape = projectile.effectiveColShape.shape
		query.transform = projectile.effectiveColShape.global_transform
		query.motion = motion
		query.collide_with_areas = true
		query.collide_with_bodies = true
		query.exclude = []

		if projectile.hitbox:
			query.exclude.append(projectile.hitbox.get_rid())

		var spaceState: PhysicsDirectSpaceState3D= projectile.get_world_3d().direct_space_state

		# Figure out how far the shape can travel
		var motionResult: PackedFloat32Array = spaceState.cast_motion(query)
		if motionResult.is_empty():
			return {}

		# motion_result[0] -- safe fraction
		# motion_result[1] -- unsafe fraction
		# 1.0 if safe: no collision
		if motionResult[0] >= 1.0:
			return {}

		# Move the query shape to the first impact position.
		var hitTransform: Transform3D = query.transform
		var epsilon: float = max(1e-3, motion.length() * 1e-3)
		hitTransform.origin += motionResult[1] * motion + epsilon * motion.normalized()
		query.transform = hitTransform
		query.motion = Vector3.ZERO

		var hits: Array = spaceState.intersect_shape(query, 8)
		
		if hits.is_empty():
			return {}

		print("Not empty 2")

		return {
			"safe_fraction": motionResult[0],
			"unsafe_fraction": motionResult[1],
			"transform": hitTransform,
			"hits": hits,
		}
	return {}

#endregion
#endregion
