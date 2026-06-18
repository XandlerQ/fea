extends Node
## Difines an interface to get inputs for player combat.
class_name PlayerCombatInputComponent

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
func get_fire_just_preseed_input() -> bool:
	return Input.is_action_just_pressed("Fire")
#endregion

#region Private

#endregion
#endregion
