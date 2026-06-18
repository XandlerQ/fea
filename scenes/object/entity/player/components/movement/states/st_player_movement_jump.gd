extends BaseStatePlayerMovement
## Idle state (no input on the ground)
class_name StatePlayerMovementJump

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
func physics_update(delta: float) -> void:
	_update_h_velocity(delta, pmc.get_air_speed(), pmc.get_air_acceleration(), pmc.get_drag())
	pmc.desiredVelocity.y = pmc.get_jump_speed() * (0.5 + 0.5 * clamp((pmc.desiredVelocity.y + pmc.get_terminal_speed()) / pmc.get_terminal_speed(), 0., 1.))
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
