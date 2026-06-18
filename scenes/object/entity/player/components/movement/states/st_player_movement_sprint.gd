extends BaseStatePlayerMovement
## Idle state (no input on the ground)
class_name StatePlayerMovementSprint

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
	_update_velocity(delta, pmc.get_sprint_speed(), pmc.get_sprint_acceleration(), pmc.get_friction()) 

#endregion

#region Private

#endregion
#endregion
