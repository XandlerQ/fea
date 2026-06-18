extends BaseStatePlayerMovement
## Idle state (no input on the ground)
class_name StatePlayerMovementFall

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
	_fall(delta, pmc.get_gravity(), pmc.get_terminal_speed())

#endregion

#region Private

#endregion
#endregion
