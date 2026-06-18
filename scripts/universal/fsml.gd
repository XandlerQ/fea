extends Node
## Finite state machine.
## Used for a controlling parrent:
## does not have _process and _physics_process itself
class_name FSML

#region Signals

#endregion

#region Exports
@export var initialState: State = null
#endregion

#region State
var states: Dictionary = {}
var state: State = null
var previousState: State = null
#endregion

#region Methods
#region System
func _ready() -> void:
	for state_node: State in find_children("*", "State"):
		states[state_node.name.to_lower()] = state_node
		state_node.finished.connect(change_state)

	await owner.ready
	if initialState:
		initialState.enter("")
		state = initialState
	else:
		state = get_child(0)
		if state:
			state.enter("")
		else:
			printerr(owner.name + ": No initial state")

func handle_input(event: InputEvent) -> void:
	if not state:
		return
	state.handle_input(event)


func update(delta: float) -> void:
	if not state:
		return
	state.update(delta)


func physics_update(delta: float) -> void:
	if not state:
		return
	state.physics_update(delta)
#endregion

#region Interface
func change_state(oldState: State, targetStateName: String, data: Dictionary = {}, forceExitEnter: bool = false) -> void:
	if targetStateName == state.name and not forceExitEnter:
		return

	if oldState != state:
		printerr(owner.name + ": Trying to transition from state " + oldState.name + " but current state is " + state.name)

	if not has_node(targetStateName):
		printerr(owner.name + ": Trying to transition to state " + targetStateName + " but it does not exist.")
		return

	var previousStatePath := state.name
	if state:
		previousState = state
		state.exit()
	state = get_node(targetStateName)
	state.enter(previousStatePath, data)

func get_state_name() -> String:
	if state:
		return state.name
	else:
		return ""

func get_previous_state_name() -> String:
	if previousState:
		return previousState.name
	else:
		return ""
#endregion

#region Private

#endregion
#endregion
