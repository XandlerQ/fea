extends Area3D
class_name Hurtbox

#region Signals
signal hit_received(atkContext: AttackContext)
#endregion

#region Exports

#endregion

#region State

#endregion

#region Methods
#region System

#endregion

#region Interface
func receive_hit(atkContext: AttackContext) -> void:
	if not atkContext: return

	hit_received.emit(atkContext)
#endregion

#region Private

#endregion
#endregion
