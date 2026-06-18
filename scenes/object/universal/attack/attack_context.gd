extends RefCounted
## Class that describes an attack context
## Created by a hitbox and passed to the
## hurtbox to process being hit
class_name AttackContext

#region State
## Stats of the attack
var attackStats: AttackStats
#endregion

#region Methods
#region System

#endregion

#region Interface
func get_damage() -> float:
	return attackStats.damage
#endregion

#region Private

#endregion