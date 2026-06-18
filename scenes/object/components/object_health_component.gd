extends Node
class_name ObjectHealthComponent

#region Signals
signal damaged(damage: float, currentHealth: float)
signal destroyed(damageSource: AttackContext)
#endregion

#region Exports
## Max health
@export var maxHealth: float = 1.
## Optional explicit hurtbox subscription
@export var hurtbox: Hurtbox = null
#endregion

#region State
## Current health
var currentHealth: float
#endregion

#region Methods
#region System
func _ready() -> void:
	# Set current health to max
	currentHealth = maxHealth

	# TODO: add hurtbox searching in the scene tree
	
#endregion

#region Interface
func apply_damage(atkContext: AttackContext) -> void:
	if not atkContext: return

	var damage: float = atkContext.get_damage()
	
	if damage <= 0.:
		return
	currentHealth = max(0., currentHealth - damage)
	damaged.emit(damage, currentHealth)

	if currentHealth <= 0.:
		destroyed.emit(atkContext)
#endregion

#region Private
func _on_hurtbox_hit_recieved(atkContext: AttackContext) -> void:
	apply_damage(atkContext)
#endregion
#endregion
