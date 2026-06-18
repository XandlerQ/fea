extends BaseStatePlayerMovement
## Idle state (no input on the ground)
class_name StatePlayerMovementOnWallCling

#region Signals

#endregion

#region Exportss

#endregion

#region State
## Wall cling timer
var wallClingTimer: Timer = null
## Timer timed out flag
var timedOut: bool = false
## Timer started flag
var timeStarted: bool = false
#endregion

#region Methods
#region System
func _ready() -> void:
	wallClingTimer = Timer.new()
	wallClingTimer.wait_time = pmc.get_wall_cling_duration()
	wallClingTimer.one_shot = true
	self.add_child(wallClingTimer)

	wallClingTimer.timeout.connect(_on_wall_cling_timer_timeout)


#endregion

#region Interface
## Called by the state machine on the engine's physics update tick.
func physics_update(delta: float) -> void:
	var normal: Vector3 = pmc.get_last_wall_normal()
	var velocity: Vector3 = pmc.get_desired_velocity()
	var duration: float = wallClingTimer.wait_time
	var frictionCurve: Curve = pmc.get_wall_cling_friction_curve()

	# Projection of the UP vector on the wall
	var upTang: Vector3 = Vector3.UP - Vector3.UP.project(normal)

	# Get tangential velocity
	var vTang: Vector3 = velocity - velocity.project(normal)

	# Split into vertical and horizontal components
	var vTangH: Vector3 = vTang - vTang.project(upTang)
	var vTangV: Vector3 = vTang.project(upTang)

	# Apply gravity	
	var gravity: Vector3 = -delta * pmc.get_wall_cling_gravity() * upTang
	vTangV += gravity

	# Start the wall slide timer when begin to go down along the wall
	if vTang.dot(upTang) < 0. and not timeStarted:
		wallClingTimer.start()
		timeStarted = true

	# Calculate the curve parameter value
	var t: float = 0.
	if timedOut or not timeStarted:
		# If timed out or the time hasn't started, take the last curve value
		# (the smallest value, i.e. no more energy to hold on)
		t = 1.0
	else:
		# Else calculate the value using the timer time_left
		t = clamp(1. - wallClingTimer.time_left / duration, 0., 1.)

	# Hadle horizontal component
	# Get magnitude
	var vTangHM: float = vTangH.length()
	if vTangHM < 1e-5:
		# Stop completely if horizontal component is very small
		vTangH = Vector3.ZERO
	else:
		# Else slow down due to friction
		var vTangHDir: Vector3 = vTangH.normalized()
		var decelH: float = delta * (pmc.get_wall_cling_horizontal_friction() + pmc.get_wall_cling_horizontal_friction_quad() * vTangHM * vTangHM)

		if vTangHM > decelH:
			vTangH -= decelH * vTangHDir
		else:
			vTangH = Vector3.ZERO


	# Hadle vertical component
	# Calculate the vertical friction
	var frictionV: float = pmc.get_wall_cling_vertical_friction() * frictionCurve.sample_baked(t)

	# Get magnitude
	var vTangVM: float = vTangV.length()
	if vTangVM < 1e-5:
		# Stop completely
		vTangV = Vector3.ZERO
	else:
		var vTangVDir: Vector3 = vTangV.normalized()
		var decelV: float = delta * (frictionV + pmc.get_wall_cling_vertical_friction_quad() * vTangVM * vTangVM)

		if vTangVM > decelV:
			vTangV -= decelV * vTangVDir
		else:
			vTangV = Vector3.ZERO

	# Change the speed
	pmc.desiredVelocity = vTangH + vTangV.limit_length(pmc.get_terminal_speed()) - pmc.get_wall_stick_speed() * normal

## Called by the state machine upon changing the active state. The `data` parameter
## is a dictionary with arbitrary data the state can use to initialize itself.
func enter(previousState: String, data := {}) -> void:
	# Initialize velocity: keep tangential part, apply approach conversion, and add stick-in
	var normal: Vector3 = pmc.get_last_wall_normal()
	var velocity: Vector3 = pmc.get_desired_velocity()
	var proj: Vector3 = velocity - velocity.project(normal)
	pmc.desiredVelocity = pmc.get_wall_cling_approach_speed_conv() * proj - pmc.get_wall_stick_speed() * normal

	timedOut = false
	timeStarted = false

	# Refresh timer duration to reflect any live-tuned value changes in pmc
	var dur := pmc.get_wall_cling_duration()
	wallClingTimer.stop()
	wallClingTimer.wait_time = dur
	
#endregion

#region Private
func _on_wall_cling_timer_timeout():
	timedOut = true
#endregion
#endregion
