extends Node
## Player component responsible for combat
class_name PlayerCombatComponent

#region Signals

#endregion

#region Exports
## Player reference
@export var player: Player = null
## Player combat input component
@export var pcic: PlayerCombatInputComponent = null
## Player movement complonent
@export var pmc: PlayerMovementComponent = null
## Associater projectile caster
@export var projectileCaster: ProjectileCasterComponent = null


## Ratio of player resolved velocity passed to the projectile initial velocity
@export var playerVelPassRatio: float = 0.
#endregion

#region State

#endregion

#region Methods
#region System
func _physics_process(delta: float) -> void:
	if pcic.get_fire_just_preseed_input():
		projectileCaster.cast_projectile(player, playerVelPassRatio * pmc.get_resolved_velocity())
#endregion

#region Interface

#endregion

#region Private

#endregion
#endregion
