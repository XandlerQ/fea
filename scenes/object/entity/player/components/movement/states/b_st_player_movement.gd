extends State
## Base state for player movement states
class_name BaseStatePlayerMovement

#region Signals

#endregion

#region Exports
## PlayerMovementComponent to control the velocity property
@export var pmc: PlayerMovementComponent = null
#endregion

#region State

#endregion

#region Methods
#region System

#endregion

#region Interface

#endregion

#region Private
func _update_velocity(delta: float, topSpeed: float, acceleration: float, friction: float) -> void:
	var inputDir: Vector2 = pmc.get_movement_input_direction()
	var inputDir3: Vector3 = VectorConverter.convert_vector_2_3(inputDir)
	var vm: float = pmc.get_desired_velocity().length()
	var vdir: Vector3 = pmc.get_desired_velocity().normalized()
	# Get the top speed
	var limMVal: float = max(vm - friction * delta, topSpeed)

	if inputDir == Vector2.ZERO:
		_apply_friction_drag(delta, friction)
		return
	
	# Initialize the velocity change variable
	var dv: Vector3 = Vector3.ZERO

	# Check if input is in the direction of deceleration
	var vdirDInputDir = vdir.dot(inputDir3)
	# If input not in the direction of velocity
	if vdirDInputDir < 0.:
		# Make the friction work with the input for quick deceleration
		dv += friction * delta * vdirDInputDir * vdir
	
	# Add the change from accelerating 
	dv += acceleration * delta * inputDir3

	# Change the speed
	pmc.desiredVelocity += dv
	pmc.desiredVelocity = pmc.desiredVelocity.limit_length(limMVal)


func _update_h_velocity(delta: float, topSpeed: float, acceleration: float, friction: float) -> void:
	var inputDir: Vector2 = pmc.get_movement_input_direction()
	var hVelocity: Vector2 = pmc.get_hv()
	var vm: float = hVelocity.length()
	var vdir: Vector2 = hVelocity.normalized()
	# Get the top speed
	var limMVal: float = max(vm - friction * delta, topSpeed)
	
	if inputDir == Vector2.ZERO:
		_apply_h_friction_drag(delta, friction)
		return
	
	# Initialize the velocity change variable
	var dv: Vector2 = Vector2.ZERO 

	# Check if input is in the direction of deceleration
	var vdirDInputDir = vdir.dot(inputDir)
	# If input not in the direction of velocity
	if vdirDInputDir < 0.:
		# Make the friction work with the input for quick deceleration
		dv += friction * delta * vdirDInputDir * vdir
	
	# Add the change from accelerating 
	dv += acceleration * delta * inputDir

	# Change the speed
	var vel2: Vector2 = VectorConverter.convert_vector_3_2(pmc.desiredVelocity)
	vel2 += dv
	vel2 = vel2.limit_length(limMVal)
	pmc.desiredVelocity.x = vel2.x
	pmc.desiredVelocity.z = vel2.y

func _apply_friction_drag(delta: float, frdr: float) -> void:
	# Check if velocity is small
	var vm: float = pmc.get_desired_velocity().length()
	if vm < 1e-5:
		# Stop completely
		pmc.desiredVelocity = Vector3.ZERO
		return
	# Otherwise slow down due to friction
	var vdir: Vector3 = pmc.get_desired_velocity().normalized()
	var decel: float = delta * frdr

	# Compare current velocity magnitude to change due to friction
	if vm > decel:
		pmc.desiredVelocity -= decel * vdir
	else:
		pmc.desiredVelocity = Vector3.ZERO

func _apply_h_friction_drag(delta: float, frdr: float) -> void:
	# Check if velocity is small
	var hVelocity: Vector2 = pmc.get_hv()
	var vm: float = hVelocity.length()
	var vdir: Vector2 = hVelocity.normalized()
	if vm < 1e-5:
		# Stop horizontal motion completely, keep vertical
		pmc.desiredVelocity.x = 0.0
		pmc.desiredVelocity.z = 0.0
		return
	# Otherwise slow down due to friction
	var decel: float = delta * frdr

	# Apply drag only to horizontal velocity
	if vm > decel:
		hVelocity -= decel * vdir
	else:
		hVelocity = Vector2.ZERO

	pmc.desiredVelocity.x = hVelocity.x
	pmc.desiredVelocity.z = hVelocity.y

func _get_next_state() -> String:
	if not pmc.is_on_floor():
		if pmc.get_desired_velocity().y > 0:
			return "Rise"
		else:
			return "Fall"
	else:
		if pmc.get_movement_input_direction().length_squared() > 1e-5:
			if pmc.get_sprint_pressed():
				return "Sprint"
			else:
				return  "Walk"
		else:
			return  "Idle"

func _fall(delta: float, gravity: float, terminalSpeed: float) -> void:
	pmc.desiredVelocity.y -= delta * gravity
	if pmc.desiredVelocity.y < -terminalSpeed:
		pmc.desiredVelocity.y = -terminalSpeed
#endregion
#endregion
