extends BaseStatePlayerMovement
## Idle state (no input on the ground)
class_name StatePlayerMovementOnWallGlide

#region Signals

#endregion

#region Exports

#endregion

#region State
## Wall glide timer
var wallGlideTimer: Timer = null
## Timer timed-out flag
var timedOut: bool = false
## Timer started flag
var timeStarted: bool = false
## Wall glide direction along the wall
var glideDirection: Vector3 = Vector3.ZERO
## Any glide direction flag
var anyGlideDirection: bool = false
#endregion

#region Methods
#region System
func _ready() -> void:
	wallGlideTimer = Timer.new()
	wallGlideTimer.wait_time = pmc.get_wall_glide_duration()
	wallGlideTimer.one_shot = true
	self.add_child(wallGlideTimer)

	wallGlideTimer.timeout.connect(_on_wall_glide_timer_timeout)
#endregion

#region Interface
## Called by the state machine on the engine's physics update tick.
func physics_update(delta: float) -> void:
	var normal: Vector3 = pmc.get_last_wall_normal()
	var velocity: Vector3 = pmc.get_desired_velocity()
	var duration: float = wallGlideTimer.wait_time

	var speedCurve: Curve = pmc.get_wall_glide_speed_curve()
	var gravityCurve: Curve = pmc.get_wall_glide_gravity_curve()

	# Projection of the UP vector on the wall
	var upTang: Vector3 = Vector3.UP - Vector3.UP.project(normal)

	# Get tangential velocity
	var vTang: Vector3 = velocity - velocity.project(normal)
	
	# Calculate the curve parameter value
	var t: float = 0.
	if timedOut or not timeStarted:
		t = 1.0
	else:
		t = clamp(1. - wallGlideTimer.time_left / duration, 0., 1.)

	# Split into vertical and horizontal components
	var vTangH: Vector3 = vTang - vTang.project(upTang)
	var vTangHM: float = vTangH.length()
	var vTangHDir: Vector3 = vTangH.normalized()

	var vTangV: Vector3 = vTang.project(upTang)
	var vTangVM: float = vTangV.length()
	var vTangVDir: Vector3 = vTangV.normalized()

	# Apply gravity
	var gravityCoeff: float = pmc.get_wall_glide_gravity() * gravityCurve.sample_baked(t)
	vTangV += -delta * gravityCoeff * upTang

	# Get target horizontal speed
	var baseHorizontalSpeed: float = pmc.get_wall_glide_speed()
	var targetHorizontalSpeed: float = baseHorizontalSpeed * speedCurve.sample_baked(t)

	var movementInputDir: Vector3 = pmc.get_movement_input_direction_3()

	# Handle undefined glide direction
	if anyGlideDirection:
		# Get tangential horizontal vector
		var tangential: Vector3 = Vector3.UP.cross(normal)
		# Set the glide direction accordingly
		var midirDtang: float = movementInputDir.dot(tangential)
		if abs(midirDtang) > 0.1:
			if movementInputDir.dot(tangential) >= 0.:
				glideDirection = tangential
			else:
				glideDirection = -tangential
			anyGlideDirection = false

	var midirDgdir: float = movementInputDir.dot(glideDirection)
	# If horizontal speed is higher than the target one,
	# or if the direction inputted is opposite of the glide direction
	# then decelerate via friction
	if vTangHM >= targetHorizontalSpeed or midirDgdir <= 0.:
		var decel: float = delta * pmc.get_wall_glide_friction()
		if decel > vTangHM:
			vTangH = Vector3.ZERO
		else:
			vTangH += -decel * vTangHDir
	# Accelerate to target speed if the input is in the same direction
	elif midirDgdir > 0.15 and not anyGlideDirection:
		var accel: float = delta * min(1.3 * midirDgdir, 1.) * pmc.get_wall_glide_acceleration()
		if vTangH.dot(glideDirection) > 0.0:
			if accel > targetHorizontalSpeed - vTangHM:
				vTangH = targetHorizontalSpeed * glideDirection
			else:
				vTangH += accel * glideDirection
		else:
			vTangH += accel * glideDirection

	# Slow down in the vertical component if moving up
	if vTangV.dot(upTang) > 0.0:
		var verticalDecel: float = delta * pmc.get_wall_glide_friction()
		if verticalDecel > vTangVM:
			vTangV = Vector3.ZERO
		else:
			vTangV += -verticalDecel * vTangVDir

	pmc.desiredVelocity = vTangH + vTangV.limit_length(pmc.get_terminal_speed()) - pmc.get_wall_stick_speed() * normal


## Called by the state machine upon changing the active state. The `data` parameter
## is a dictionary with arbitrary data the state can use to initialize itself.
func enter(previousState: String, data := {}) -> void:
	# Apply the wall approach speed as the "vertical" speed along the wall
	var normal: Vector3 = pmc.get_last_wall_normal()
	var was: float = pmc.get_last_wall_approach_speed()

	# Get the most vertical direction along the wall
	var tangential: Vector3 = Vector3.UP.cross(normal)
	var vertical: Vector3 = normal.cross(tangential)

	var coeff: float = min(pmc.get_wall_glide_approach_speed_conv() * was, pmc.get_wall_glide_max_conv_vertical_speed())

	pmc.desiredVelocity += coeff * vertical

	# Determine the wall glide direction
	var fwdProjected: Vector3 = pmc.get_forward_direction().project(tangential)

	# Handle the case of looking almost along the wall normal
	if fwdProjected.length() < 0.1:
		anyGlideDirection = true
		glideDirection = Vector3.ZERO
	else:
		glideDirection = pmc.get_forward_direction().project(tangential).normalized()

	timedOut = false
	timeStarted = true

	var dur: float = pmc.get_wall_glide_duration()
	wallGlideTimer.wait_time = dur
	wallGlideTimer.start()

	
#endregion

#region Private
func _on_wall_glide_timer_timeout():
	timedOut = true
	timeStarted = false
#endregion
#endregion
