extends Area3D
## Universal hitbox class
class_name Hitbox

#region Signals
signal hit_hurtbox(hbox: Hurtbox)
#endregion

#region Exports
## An export for an attacker object that owns this hitbox.
## This could be a weapon, a projectile, hazards, etc.
## This object may have to be able to provide additional information
## to this hitbox.
@export var attacker: Node = null

## The stats of the attacks of this hitbox
@export var attackStats: AttackStats = null

## Same hurtbox hit cooldown
@export var hitCooldown: float = 0.1

## Active collision shape
## Should be the one that this Hitbox actually uses for collision detection
@export var colShape: CollisionShape3D = null
#endregion

#region State
## Dictionary for the last time hurtboxes were hit
var lastHitTimeDict: Dictionary = {}

#endregion

#region Methods
#region System
func _ready() -> void:
	area_entered.connect(_on_area_entered)

	if not colShape:
		var colShapeCand := find_children("*", "CollisionShape3D", true, false)
		if colShapeCand.size() > 0:
			colShape = colShapeCand[0] as CollisionShape3D

#endregion

#region Interface
## A function that forces a hit on a hurtbox without collision detection required.
## Used by attacking objects if they use a separate detection method.
func apply_hit_to_hurtbox(hbox: Hurtbox) -> void:
	if _handle_last_hit_dict(hbox):
		hbox.receive_hit(_generate_attack_context())
		hit_hurtbox.emit(hbox)
#endregion

#region Private
func _handle_last_hit_dict(hurtbox: Hurtbox) -> bool:
	if hitCooldown <= 0.:
		return true
	
	var id: int = hurtbox.get_instance_id()
	var now: float = Time.get_ticks_msec() / 1000.

	if lastHitTimeDict.has(id):
		var dt: float = now - float(lastHitTimeDict[id])
		if dt < hitCooldown:
			return false
	
	lastHitTimeDict[id] = now
	return true

func _generate_attack_context() -> AttackContext:
	var attackContext: AttackContext = AttackContext.new()
	attackContext.attackStats = self.attackStats
	return attackContext

func _on_area_entered(area: Area3D) -> void:
	if area is Hurtbox:
		if _handle_last_hit_dict(area):
			area.receive_hit(_generate_attack_context())
			hit_hurtbox.emit(area)
#endregion
#endregion
