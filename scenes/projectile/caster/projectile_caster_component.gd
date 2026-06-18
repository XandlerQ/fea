extends Node
class_name ProjectileCasterComponent

#region Signals

#endregion

#region Exports
## Test projectile to cast
@export var projectilePackedScene: PackedScene
## Projectile spawn point
@export var projectileSpawnPoint: Marker3D
## Container for the spawned projectiles
@export var projectileContainer: ProjectileContainer

@export var pcic: PlayerCombatInputComponent
#endregion

#region State

#endregion

#region Methods
#region System
func _ready() -> void:
	# Search for the prjectile container in the tree
	if not projectileContainer:
		var containers := get_tree().get_nodes_in_group("projectile_containers")

		for node in containers:
			if node is ProjectileContainer:
				print("Found container")
				projectileContainer = node

#endregion

#region Interface
func cast_projectile(attacker: Node, initialVelocity: Vector3 = Vector3.ZERO) -> void:
	# Create a new instance of a projectile
	var projectile: Projectile = projectilePackedScene.instantiate() as Projectile

	# Set up all of the information for the launch
	var origin: Vector3 = projectileSpawnPoint.global_position
	var launch_direction: Vector3 = -projectileSpawnPoint.global_transform.basis.z
	var up_direction: Vector3 = projectileSpawnPoint.global_transform.basis.y
	var p_to_look_at: Vector3 = origin + launch_direction

	# Make sure that the initial orientation is correct
	projectile.look_at_from_position(origin, p_to_look_at, up_direction)
	
	projectileContainer.add_child(projectile)
	projectile.launch(origin, launch_direction, initialVelocity, attacker)

#endregion

#region Private

#endregion
#endregion
