extends Node3D
## Defines a pivot point (head) for the player camera.
class_name PlayerCameraNode

#region Signals

#endregion

#region Exports
## Player movement component
@export var pmc: PlayerMovementComponent = null

## Player camera
@export var playerCamera: PlayerCamera = null

## Head default position
@export var defaultPos: Vector3 = Vector3(0, 0.5, 0)

## Headbob idle angular speed
@export var hbIdleSpeed: float = 0.65
## Headbob moving angular speed
@export var hbMoveSpeed: float = 10.2
## Headbob idle amplitude
# @export var hbIdleAmp: Vector2 = Vector2(0.001, 0.002)
@export var hbIdleAmp: Vector2 = Vector2(0.0, 0.0)
## Headbob moving amplitude
@export var hbMoveAmp: Vector2 = Vector2(0.01, 0.02)

## Headbob origin hbSm speed
@export var orSm: float = 17.
## Headbob hbSm speed
@export var hbSm: float = 17.

## Camera kick on jump strength
@export var jumpKickStr: float = 0.025
## Jump kick threshold velocity change
@export var jumpThrV: float = 3.
## Camera kick on land strength
@export var landKickStr: float = 0.04
## Land kick threshold velocity change
@export var landThrV: float = 3.
## Camera kick curve
@export var camKickCurve: Curve
## Camera kick jumping duration
@export var jumpKickDur: float = 0.1
## Camera kick landing duration
@export var landKickDur: float = 0.07
#endregion

#region State
## Max player horizontal speed
var maxHSpeed: float
## Max player vertical speed
var maxVSpeed: float

## Current headbob origin
var origin: Vector3
## Target headbob origin
var targetOrigin: Vector3
## Current headbob angle
var phase: float = 0.

## Current vertical velocity kick
var kick: float = 0.
## Previous vertical velocity
var prevVY: float = 0.
## Current kick strength
var curKickStr: float = 0.
## Camera kick timer
var camKickTimer: Timer
## Runtime validity flag for required references.
var runtimeValid: bool = false
#endregion

#region Methods
#region System
func _ready() -> void:
	runtimeValid = _validate_required_references()
	if not runtimeValid:
		set_physics_process(false)
		return

	if not camKickCurve:
		push_warning("%s: camKickCurve is null, using fallback constant curve." % name)
		camKickCurve = _make_constant_curve(1.0)

	origin = defaultPos
	targetOrigin = defaultPos

	# Initialize camera kick timer
	camKickTimer = Timer.new()
	camKickTimer.one_shot = true
	self.add_child(camKickTimer)

	# Grab the max speeds from the PMC
	maxHSpeed = pmc.get_max_th_h_speed()
	maxVSpeed = pmc.get_terminal_speed()

func _physics_process(delta: float) -> void:
	if not runtimeValid:
		return
	_head_bob(delta)
	prevVY = pmc.get_resolved_velocity().y
#endregion

#region Interface

#endregion

#region Private
func _advance_phase(delta: float, aSp: float) -> void:
	phase += delta * aSp
	phase = fmod(phase, 2 * PI)

func _determine_target_origin() -> void:
	# Some camera position logic (e.g. sneak)
	targetOrigin = defaultPos

func _update_kick() -> void:
	kick = 0.

	var vy: float = pmc.get_resolved_velocity().y
	var dv: float = vy - prevVY
	var grndd: bool = pmc.is_on_floor()

	# Handle jump
	if dv >= jumpThrV and not grndd:
		curKickStr = jumpKickStr * clamp(dv / maxVSpeed, 0., 1.)
		camKickTimer.start(jumpKickDur)
	
	# Handle landing
	if dv >= landThrV and grndd:
		var t: float = clamp(dv / maxVSpeed, 0., 1.)
		curKickStr = -lerp(0.25 * landKickStr, landKickStr, t)
		camKickTimer.start(landKickDur)
	
	if not camKickTimer.is_stopped():
		var t = clamp(1. - camKickTimer.time_left / camKickTimer.wait_time, 0., 1.)
		kick = curKickStr * camKickCurve.sample_baked(t)
	


func _head_bob(delta: float) -> void:
	_determine_target_origin()
	# Interpolate to target origin
	origin = transform.origin.lerp(targetOrigin, 1.0 - exp(-orSm * delta))

	# Determine idle/moving blend weights
	var speed: float = pmc.get_resolved_velocity().length()
	# Moving ratio
	var r: float = clamp(speed / maxHSpeed, 0., 1.)
	# Smoothen the ratio
	r = smoothstep(0., 1., r)

	# Calculate the weights
	var idleW: float = 1 - r
	var moveW: float = r

	# Calculate angular speed and amplitude based on weights
	var omega: float = idleW * hbIdleSpeed + moveW * hbMoveSpeed
	var amp: Vector2 = idleW * hbIdleAmp + moveW * hbMoveAmp

	# Get the airborne multiplier
	var airborne: float = (float)(pmc.is_on_floor())

	# Advance phase
	_advance_phase(delta, omega)

	# Calculate offsets
	var xOff: float = cos(phase) * amp.x * airborne
	var yOff: float = sin(2. * phase) * amp.y * airborne

	# Update kick
	_update_kick()

	# Calculate target position
	var targetPos: Vector3 = origin + Vector3(xOff, yOff, 0.)

	# Interpolate to target
	transform.origin = transform.origin.lerp(targetPos, 1.0 - exp(-hbSm * delta))
	transform.origin.y += kick

func _validate_required_references() -> bool:
	var valid := true

	if not pmc:
		push_error("%s: Missing required reference 'pmc'." % name)
		valid = false
	if not playerCamera:
		push_warning("%s: 'playerCamera' is not assigned." % name)

	return valid

func _make_constant_curve(value: float) -> Curve:
	var c := Curve.new()
	c.add_point(Vector2(0.0, value))
	c.add_point(Vector2(1.0, value))
	return c
#endregion
#endregion
