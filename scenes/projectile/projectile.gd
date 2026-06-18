extends Node3D
## Base class for projectiles
class_name Projectile

#region Signals

#endregion

#region Exports
## Projectile hitbox
@export var hitbox: Hitbox = null

## Collision detection method enum
## For Hitbox make sure that the projectile has a Hitbox
## and that the CollisionShape3D for that Hitbox is enabled.
## For Raycast, Sweep the CollisionShape3D has to be disabled
## Raycast and Sweep are the tunneling handling methods.
## Raycast: casts a ray from the previous position to the current
## Sweep: sweeps a collision from the previous position to the current
enum ColDetMethod {Hitbox, Raycast, Sweep}
## Collision detection method
@export var cdm: ColDetMethod = ColDetMethod.Hitbox

## Effective collision shape to use in Sweep collision detection mode
@export var effectiveColShape: CollisionShape3D = null

## Lifetime timer node
@onready var lifetimeTimer: Timer = $LifetimeTimer
## Lifetime
@export var lifetime: float = 20.

## Projectile movement component reference
@export var pmc: ProjectileMovementComponent = null
#endregion

#region State

#endregion

#region Methods
#region System
func _ready() -> void:
	# Collision shape work
	if cdm == ColDetMethod.Hitbox:
		if not hitbox:
			push_error("%s: Missing required reference 'hitbox'." % name)
		else:
			hitbox.area_entered.connect(_on_area_entered)
			hitbox.body_entered.connect(_on_object_entered)
	else:
		if hitbox.colShape:
			if not hitbox.colShape.disabled:
				hitbox.colShape.set_deferred("disabled", true)
	
	# Lifetime timer setup
	lifetimeTimer.wait_time = lifetime
	lifetimeTimer.one_shot = true
	lifetimeTimer.timeout.connect(_on_lifetime_timer_timeout)
	lifetimeTimer.start()
#endregion

#region Interface
func  handle_hit(hit: Dictionary) -> void:
	var collider: Object = hit.get("collider", null)

	if collider is Hurtbox:
		if hitbox:
			hitbox.apply_hit_to_hurtbox(collider)
		_on_area_entered(collider)
	else:
		_on_object_entered(collider)
	
func launch(origin: Vector3, direction: Vector3, initialVelocity: Vector3 = Vector3.ZERO, attacker: Node = null) -> void:
	# Set the projectile initial position
	global_position = origin

	# Pass the attacker reference to the hitbox
	if hitbox:
		hitbox.attacker = attacker

	if pmc:
		pmc.launch(direction, initialVelocity)
#endregion

#region Private
## Hurting the hurtbox is defined in the Hitbox itself.
## This method is for optional additional behavior (tied to projectiles)
func _on_area_entered(area: Area3D) -> void:
	## TODO: add a different option for piercing projectiles
	print("Projectile: area entered: %s" % area)
	_despawn()

## Non-hurtbox object hit behavior.
func _on_object_entered(object: Node3D) -> void:
	print("Projectile: object entered: %s" % object)
	# TODO: perhaps a safer way to handle the projectile to not collide with the actor launching it
	if object == hitbox.attacker:
		return
	_despawn()

func _on_lifetime_timer_timeout() -> void:
	_despawn()

func _despawn() -> void:
	print("Despawning projectile")
	queue_free()
#endregion
#endregion
