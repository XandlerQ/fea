extends BaseStatePlayerMovement
## Idle state (no input on the ground)
class_name StatePlayerMovementWallJump

#region Signals

#endregion

#region Exports
## Terminal speed
@export var wallTerminalSpeed: float = 10.
#endregion

#region State

#endregion

#region Methods
#region System

#endregion

#region Interface
## Called by the state machine on the engine's physics update tick.
func physics_update(delta: float) -> void:
	# Get normal
	var normal: Vector3 = pmc.get_last_wall_normal()
	var velocity: Vector3 = pmc.get_desired_velocity()

	# Projection of the UP vector on the wall
	var upTang: Vector3 = Vector3.UP - Vector3.UP.project(normal)
	# Get tangential velocity
	var vTang: Vector3 = velocity - velocity.project(normal)
	var vTangH: Vector3 = vTang - vTang.project(upTang)

	# Get jump impact direction
	var jumpDir = (0.35 * normal + 0.65 * Vector3.UP).normalized()

	# Apply jump
	pmc.desiredVelocity = vTangH + pmc.get_wall_jump_speed() * (0.5 + 0.5 * clamp((pmc.desiredVelocity.y + pmc.get_terminal_speed()) / pmc.get_terminal_speed(), 0., 1.)) * jumpDir

	# Request state change
	var targetStateName: String = ""
	if pmc.desiredVelocity.y > 0:
		targetStateName = "Rise"
	else:
		targetStateName = "Fall"
	finished.emit(self, targetStateName)

#endregion

#region Private

#endregion
#endregion
