extends Node
## Defines controlled orientation (rotation) behavior.
class_name ProjectileOrientationComponent

#region Signals

#endregion

#region Exports
@export_group("References")
## Controlled object reference
@export var controlled: Node3D = null
## Projectile movement component
@export var prmc: ProjectileMovementComponent = null

## Align with movement direction flag.
## If true the controlled always points 
## in the direcion of travel.
@export var alignWithMovement: bool = true

## Angular velocity for roll rotation.
@export var rollAngularVelocity: float = 25.
#endregion

#region State
## Current roll angle.
var rollAngle: float = 0.
#endregion

#region Methods
#region System
func _physics_process(delta: float) -> void:
	var speed: float = prmc.desiredVelocity.length()

	if alignWithMovement and speed >= 1e-3:
		var pos = controlled.global_position
		var newPos = pos + prmc.desiredVelocity / speed
		controlled.look_at(newPos)
	
	if rollAngularVelocity >= 1e-5:
		_update_roll_angle(delta)
		controlled.rotate_object_local(Vector3.FORWARD, rollAngle)

#endregion

#region Interface

#endregion

#region Private
func _update_roll_angle(delta: float) -> void:
	rollAngle += delta * rollAngularVelocity
#endregion
#endregion
