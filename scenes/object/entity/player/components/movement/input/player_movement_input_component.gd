extends Node
## Defines an interface to get inputs
## for player movement.
class_name PlayerMovementInputComponent

#region Signals
signal caught_input_event_mouse_motion(event: InputEventMouseMotion)
#endregion

#region Exports

#endregion

#region State

#endregion

#region Methods
#region System
func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		caught_input_event_mouse_motion.emit(event)
#endregion

#region Interface
func get_movement_direction_input() -> Vector2:
	return Input.get_vector("MLeft", "MRight", "MForward", "MBackward")

func get_sprint_pressed() -> bool:
	return Input.is_action_pressed("MSprint")

func get_dash_just_pressed() -> bool:
	return Input.is_action_just_pressed("MDash")

func get_sneak_pressed() -> bool:
	return Input.is_action_pressed("MSneak")

func get_jump_just_pressed() -> bool:
	return Input.is_action_just_pressed("MJump")

func get_jump_pressed() -> bool:
	return Input.is_action_pressed("MJump")
#endregion

#region Private

#endregion
#endregion
