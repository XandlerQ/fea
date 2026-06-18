extends Node
## Virtual base class for all states.
class_name State

#region Signals
## Emitted when the state finishes and wants to transition to another state.
## For state driven transitions.
signal finished(oldState: State, targetStatePath: String, data: Dictionary)
#endregion

#region Exports
## Indicates if this state blocks external transition requests.
## Useful for non-interruptible states (e.g. dash, attack windup).
@export var blocksExternalTransitions: bool = false
#endregion

#region State

#endregion

#region Methods
#region System

#endregion

#region Interface
## Indicates if this state blocks external transition requests.
func blocks_external_transitions() -> bool:
	return blocksExternalTransitions

## Called by the state machine when receiving unhandled input events.
func handle_input(_event: InputEvent) -> void:
	pass

## Called by the state machine on the engine's main loop tick.
func update(_delta: float) -> void:
	pass

## Called by the state machine on the engine's physics update tick.
func physics_update(_delta: float) -> void:
	pass

## Called by the state machine upon changing the active state. The `data` parameter
## is a dictionary with arbitrary data the state can use to initialize itself.
func enter(previousState: String, data := {}) -> void:
	pass

## Called by the state machine before changing the active state. Use this function
## to clean up the state.
func exit() -> void:
	pass
#endregion

#region Private

#endregion
#endregion
