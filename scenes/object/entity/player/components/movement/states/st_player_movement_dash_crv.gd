extends BaseStatePlayerMovement
## Idle state (no input on the ground)
class_name StatePlayerMovementDashCrv

#region Signals

#endregion

#region Exports

#endregion

#region State
## Dash duration timer
var dashTimer: Timer = null
## Dash direction
var dashDirection: Vector3 = Vector3.ZERO
#endregion

#region Methods
#region System
func _ready() -> void:
	dashTimer = Timer.new()
	dashTimer.wait_time = pmc.get_dash_duration()
	dashTimer.one_shot = true
	self.add_child(dashTimer)

	dashTimer.timeout.connect(_on_dash_timer_timeout)
#endregion

#region Interface
## Called by the state machine on the engine's physics update tick.
func physics_update(_delta: float) -> void:
	if not dashTimer or not pmc:
		return

	var speedCurve: Curve = pmc.get_dash_speed_curve()
	if not speedCurve:
		return

	var t: float = clamp(1. - dashTimer.time_left / pmc.get_dash_duration(), 0., 1.)
	var sp: float = speedCurve.sample_baked(t) * pmc.get_dash_speed()
	var dash: Vector3 = dashDirection * sp

	pmc.desiredVelocity = dash
	

## Called by the state machine upon changing the active state. The `data` parameter
## is a dictionary with arbitrary data the state can use to initialize itself.
func enter(_previousState: String, _data := {}) -> void:
	dashTimer.start()
	if pmc.is_on_floor() or not pmc.get_cam_dash():
		var mDir: Vector2 = pmc.get_movement_input_direction()
		if mDir.length_squared() < 1e-5:
			mDir = pmc.get_forward_h_direction()
		dashDirection = VectorConverter.convert_vector_2_3(mDir)
	else:
		# Airborne: get input direction
		var input: Vector2 = pmc.get_movement_direction_input()
		# If the direction is "forward", including diagonals, or none, then use camera
		var use_camera: bool = (input.length_squared() < 1e-5) or (input.y < -1. + 1e-5)
		if use_camera:
			dashDirection = _get_camera_forward_clamped()
		elif input.y < -1e-5:
			var side: Vector3 = Vector3.ZERO
			if input.x > 0.:
				side = VectorConverter.convert_vector_2_3(pmc.get_right_h_direction())
			else:
				side = VectorConverter.convert_vector_2_3(pmc.get_left_h_direction())
			dashDirection = (_get_camera_forward_clamped() + side).normalized()
		else:
			var mDir: Vector2 = pmc.get_movement_input_direction()
			dashDirection = VectorConverter.convert_vector_2_3(mDir)
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

func _on_dash_timer_timeout():
	finished.emit(self, _get_next_state())
#endregion
#endregion
