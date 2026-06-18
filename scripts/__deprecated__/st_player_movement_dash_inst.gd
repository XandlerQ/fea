extends BaseStatePlayerMovement
## Idle state (no input on the ground)
class_name StatePlayerMovementDashInst

#region Signals

#endregion

#region Exports

#endregion

#region State

#endregion

#region Methods
#region System

#endregion

#region Interface
## Called by the state machine on the engine's physics update tick.
func physics_update(_delta: float) -> void:
	var dashSpeed: float = pmc.get_dash_speed()
	var dash: Vector3

	if pmc.is_on_floor():
		var mDir: Vector2 = pmc.get_movement_input_direction()
		if mDir.length_squared() < 1e-5:
			mDir = pmc.get_forward_h_direction()
		dash = VectorConverter.convert_vector_2_3(mDir) * dashSpeed
	else:
		# Airborne: get input direction
		var input: Vector2 = pmc.get_movement_direction_input()
		# If the direction is "forward", including diagonals, or none, then use camera
		var use_camera: bool = (input.length_squared() < 1e-5) or (input.y < -1. + 1e-5)
		if use_camera:
			dash = _get_camera_forward_clamped() * dashSpeed
		elif input.y < -1e-5:
			var side: Vector3 = Vector3.ZERO
			if input.x > 0.:
				side = VectorConverter.convert_vector_2_3(pmc.get_right_h_direction())
			else:
				side = VectorConverter.convert_vector_2_3(pmc.get_left_h_direction())
			dash = (_get_camera_forward_clamped() + side).normalized() * dashSpeed
		else:
			var mDir: Vector2 = pmc.get_movement_input_direction()
			dash = VectorConverter.convert_vector_2_3(mDir) * dashSpeed

	pmc.desiredVelocity += dash
	finished.emit(self, _get_next_state())
#endregion

#region Private
func _get_camera_forward_clamped() -> Vector3:
	var look: Vector3 = -pmc.pcn.global_transform.basis.z
	
	# Pitch of the look vector
	var pitch: float = asin(look.y)

	# Clamp
	var clampedPitch: float = clamp(pitch, pmc.get_min_dash_pitch(), pmc.get_max_dash_pitch())

	# Get horizontal direction
	var fwd: Vector3 = -pmc.player.global_transform.basis.z
	var dir: Vector2 = Vector2(fwd.x, fwd.z)
	dir = dir.normalized()

	var c := cos(clampedPitch)
	var s := sin(clampedPitch)
	return Vector3(dir.x * c, s, dir.y * c).normalized()
#endregion
#endregion
