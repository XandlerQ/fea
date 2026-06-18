extends BaseStatePlayerMovement
## Idle state (no input on the ground)
class_name StatePlayerMovementRise

#region Signals

#endregion

#region Exports

#endregion

#region State
## Jump released flag
var jumpReleased: bool = false
#endregion

#region Methods
#region System

#endregion

#region Interface
## Called by the state machine on the engine's physics update tick.
func physics_update(delta: float) -> void:
	_update_h_velocity(delta, pmc.get_air_speed(), pmc.get_air_acceleration(), pmc.get_drag())

	if not pmc.get_jump_pressed():
		jumpReleased = true
	
	if not jumpReleased:
		pmc.desiredVelocity.y -= delta * pmc.get_rise_gravity()
	else:
		pmc.desiredVelocity.y -= delta * pmc.get_jump_release_gravity()

## Called by the state machine before changing the active state. Use this function
## to clean up the state.
func exit() -> void:
	jumpReleased = false
#endregion

#region Private

#endregion
#endregion
