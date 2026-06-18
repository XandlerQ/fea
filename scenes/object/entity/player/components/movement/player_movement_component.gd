extends Node
## Defines player movement behavior.
## Serves as an interface between
## PlayerMovementInputComponent and the movement state machine,
## As well as the PlayerCameraNode
class_name PlayerMovementComponent

#region Signals

#endregion

#region Exports
@export_group("References")
## Player referece
@export var player: Player = null
## PlayerMovementInputComponent reference
@export var pmic: PlayerMovementInputComponent = null
## PlayerCameraNode reference
@export var pcn: PlayerCameraNode = null
## Movement finite state machine (light)
@export var mfsml: FSML = null

@export_group("Movement")

@export_subgroup("Idle")
## Friction (grounded)
@export var friction: float = 35.

@export_subgroup("Walk")
## Walk top speed
@export var walkSpeed: float = 5.
## Walk acceleration
@export var walkAcceleration: float = 32.

@export_subgroup("Sprint")
## Sprint top speed
@export var sprintSpeed: float = 7.5
## Sprint acceleration
@export var sprintAcceleration: float = 50.

@export_subgroup("Rise and Fall")
## Terminal vertical speed (airborne)
@export var terminalSpeed: float = 30.
## Air friction (drag)
@export var drag: float = 1.
## Max horizontal speed (airborne),
## i.e. max speed to obtain due to movement input
@export var airSpeed: float = 2.
## Airborne acceleration
@export var airAcceleration: float = 17.
## Default gravity
@export var gravity: float = 1.5 * ProjectSettings.get_setting("physics/3d/default_gravity")
## Rise gravity
@export var riseGravity: float = 1.3 * ProjectSettings.get_setting("physics/3d/default_gravity")
## Jump release gravity
@export var jumpRelGravity: float = 2.8 * ProjectSettings.get_setting("physics/3d/default_gravity")

@export_subgroup("Jump")
## Jump speed added to desiredVelocity.y on jump input
@export var jumpSpeed: float = 6.3
## Jump buffer time
@export var jumpBuffer: float = 0.1
## Jump buffer timer
var jumpBufferTimer: Timer
## Coyote time
@export var coyoteTime: float = 0.1
## Coyote timer
var coyoteTimer: Timer
## Air jumps available
@export var airJumps: int = 1
## Air jump counter
var airJumpCounter: int = 0

@export_subgroup("Dash")
## Dash speed
@export var dashSpeed: float = 10.
## Dash duration
@export var dashDuration: float = 0.11
## Dash speed moudlation curve
@export var dashSpeedCurve: Curve
## Use camera for dash direction
@export var camDash: bool = false
## Dash pitch angle positive limit
@export var maxDashPitch: float = PI / 4.
## Dash pitch angle negative limit
@export var minDashPitch: float = -PI / 4.
## Dash cooldown time
@export var dashCd: float = 0.5
## Dash cooldown timer
var dashCdTimer: Timer
## Air dashes available
@export var airDashes: int = 1
## Air dash counter
var airDashCounter: int = 0


@export_subgroup("OnWallGeneral")
## Wall stick speed
@export var wallStickSpeed: float = 1.
## Max incline angle cosine
@export var wallDotUpLimit: float = sqrt(2.) / 2.
## Min wall approach speed
@export var minWallApproachSpeed: float = 0.2
## Last wall normal saved for coyote timer wall jump
var lastWallNormal: Vector3 = Vector3.ZERO
## Last wall approach speed
var lastWallApproachSpeed: float = 0.
## Wall jump coyote time
@export var wallCoyoteTime: float = 0.1
## Wall disengage cosine
@export var wallDisengageCos: float = 0.55
## Wall jump coyote timer
var wallCoyoteTimer: Timer
## Wall contact flag
var wallContact: bool = false


@export_subgroup("OnWallCling")
## Wall horizontal friction
@export var wallClingHorizontalFriction: float = 9.
## Wall horizontal friction quadratic
@export var wallClingHorizontalFrictionQuad: float = 0.63
## Wall vertical friction
@export var wallClingVerticalFriction: float = 1.05 * ProjectSettings.get_setting("physics/3d/default_gravity")
## Wall vertical friction quadratic
@export var wallClingVerticalFrictionQuad: float = 0.21
## Wall gravity
@export var wallClingGravity: float = 1.2 * ProjectSettings.get_setting("physics/3d/default_gravity")
## Wall cling gravity curve
@export var wallClingFrictionCurve: Curve
## Wall cling time
@export var wallClingDuration: float = 2.5
## Approach speed conversion rate
@export var wallClingApproachSpeedConv: float = 0.85
## Max converted vertical speed
@export var wallClingMaxConvVerticalSpeed: float = 3.32


@export_subgroup("OnWallGlide")
## Wall gravity
@export var wallGlideGravity: float = 1. * ProjectSettings.get_setting("physics/3d/default_gravity")
## Wall max speed
@export var wallGlideSpeed: float = 9.5
## Wall glide speed curve
@export var wallGlideSpeedCurve: Curve
## Wall glide friction
@export var wallGlideFriction: float = 8.
## Wall glide gravity curve
@export var wallGlideGravityCurve: Curve
## Wall glide duration
@export var wallGlideDuration: float = 0.5
## Wall acceleration
@export var wallGlideAcceleration: float = 32.
## Approach speed conversion rate
@export var wallGlideApproachSpeedConv: float = 0.85
## Max converted vertical speed
@export var wallGlideMaxConvVerticalSpeed: float = 3.32


@export_subgroup("WallJump")
## Wall jump speed
@export var wallJumpSpeed: float = 8.


@export_subgroup("Camera")
## Mouse sensitivity
@export var sensitivity: float = 0.002
## Min camera pitch angle
@export var minCamPitch: float = -1.5
## Max camera pitch angle
@export var maxCamPitch: float = 1.5
#endregion

#region State
## Velocity of the player controlled by the state machine
var desiredVelocity: Vector3 = Vector3.ZERO
## Post move_and_slide desiredVelocity resolved by the physics solver
var resolvedVelocity: Vector3 = Vector3.ZERO
## Runtime validity flag for required references.
var runtimeValid: bool = false
#endregion

#region Methods
#region System
func _ready() -> void:	# Connect the PlayerMovementInputComponent mouse input signal
	runtimeValid = _validate_required_references()
	if not runtimeValid:
		set_physics_process(false)
		return

	_ensure_required_curves()

	if pmic:
		pmic.caught_input_event_mouse_motion.connect(_on_pmic_caught_input_event_mouse_motion)
	
	# Create the jump buffer timer
	jumpBufferTimer = Timer.new()
	jumpBufferTimer.wait_time = jumpBuffer
	jumpBufferTimer.one_shot = true
	self.add_child(jumpBufferTimer)

	# Create the coyote timer
	coyoteTimer = Timer.new()
	coyoteTimer.wait_time = coyoteTime
	coyoteTimer.one_shot = true
	self.add_child(coyoteTimer)

	# Create dash timer
	dashCdTimer = Timer.new()
	dashCdTimer.wait_time = dashCd
	dashCdTimer.one_shot = true
	self.add_child(dashCdTimer)

	# Create the wall coyote timer
	wallCoyoteTimer = Timer.new()
	wallCoyoteTimer.wait_time = wallCoyoteTime
	wallCoyoteTimer.one_shot = true
	self.add_child(wallCoyoteTimer)

func _physics_process(delta: float) -> void:
	if not runtimeValid:
		return

	_update_wall_contact()
	_update_ceiling_contact()
	_handle_state_change()

	mfsml.physics_update(delta)
	player.velocity = desiredVelocity
	player.move_and_slide()
	resolvedVelocity = player.velocity

	# Keep gameplay-owned vertical desiredVelocity physically consistent on hard contacts.
	if player.is_on_ceiling() and desiredVelocity.y > 0.:
		desiredVelocity.y = 0.
	if player.is_on_floor() and desiredVelocity.y < 0.:
		desiredVelocity.y = 0.


#endregion

#region Interface
func get_movement_input_direction() -> Vector2:
	var mdi: Vector2 = pmic.get_movement_direction_input()
	var gd: Vector3 = (player.transform.basis * Vector3(mdi.x, 0, mdi.y)).normalized();
	var gd2: Vector2 = Vector2(gd.x, gd.z).normalized()
	return gd2

func get_movement_input_direction_3() -> Vector3:
	var mdi: Vector2 = pmic.get_movement_direction_input()
	var gd: Vector3 = (player.transform.basis * Vector3(mdi.x, 0, mdi.y)).normalized();
	return gd.normalized()

func get_movement_direction_input() -> Vector2:
	return pmic.get_movement_direction_input().normalized()

func get_forward_direction() -> Vector3:
	return -player.global_transform.basis.z

func get_forward_h_direction() -> Vector2:
	var gd2: Vector2 = VectorConverter.convert_vector_3_2(-player.global_transform.basis.z)
	return gd2

func get_left_h_direction() -> Vector2:
	var gd2: Vector2 = VectorConverter.convert_vector_3_2(-player.global_transform.basis.x)
	return gd2

func get_right_h_direction() -> Vector2:
	var gd2: Vector2 = VectorConverter.convert_vector_3_2(player.global_transform.basis.x)
	return gd2

func get_backward_h_direction() -> Vector2:
	var gd2: Vector2 = VectorConverter.convert_vector_3_2(player.global_transform.basis.z)
	return gd2

func get_sprint_pressed() -> bool:
	return pmic.get_sprint_pressed()

func get_jump_pressed() -> bool:
	return pmic.get_jump_pressed()

func get_friction() -> float:
	return friction

func get_walk_speed() -> float:
	return walkSpeed

func get_walk_acceleration() -> float:
	return walkAcceleration

func get_sprint_speed() -> float:
	return sprintSpeed

func get_sprint_acceleration() -> float:
	return sprintAcceleration

func get_terminal_speed() -> float:
	return terminalSpeed

func get_drag() -> float:
	return drag

func get_air_speed() -> float:
	return airSpeed

func get_air_acceleration() -> float:
	return airAcceleration

func get_gravity() -> float:
	return gravity

func get_rise_gravity() -> float:
	return riseGravity

func get_jump_release_gravity() -> float:
	return jumpRelGravity

func get_jump_speed() -> float:
	return jumpSpeed

func get_dash_speed() -> float:
	return dashSpeed

func get_dash_duration() -> float:
	return dashDuration

func get_dash_speed_curve() -> Curve:
	return dashSpeedCurve

func get_cam_dash() -> bool:
	return camDash

func get_max_dash_pitch() -> float:
	return maxDashPitch

func get_min_dash_pitch() -> float:
	return minDashPitch

func get_wall_stick_speed() -> float:
	return wallStickSpeed

func get_last_wall_normal() -> Vector3:
	return lastWallNormal

func get_last_wall_approach_speed() -> float:
	return lastWallApproachSpeed

func get_wall_contact_flag() -> bool:
	return wallContact

func get_wall_cling_horizontal_friction() -> float:
	return wallClingHorizontalFriction

func get_wall_cling_horizontal_friction_quad() -> float:
	return wallClingHorizontalFrictionQuad

func get_wall_cling_vertical_friction() -> float:
	return wallClingVerticalFriction

func get_wall_cling_vertical_friction_quad() -> float:
	return wallClingVerticalFrictionQuad

func get_wall_cling_gravity() -> float:
	return wallClingGravity

func get_wall_cling_friction_curve() -> Curve:
	return wallClingFrictionCurve

func get_wall_cling_duration() -> float:
	return wallClingDuration

func get_wall_cling_approach_speed_conv() -> float:
	return wallClingApproachSpeedConv

func get_wall_cling_max_conv_vertical_speed() -> float:
	return wallClingMaxConvVerticalSpeed

func get_wall_glide_gravity() -> float:
	return wallGlideGravity

func get_wall_glide_speed() -> float:
	return wallGlideSpeed

func get_wall_glide_speed_curve() -> Curve:
	return wallGlideSpeedCurve

func get_wall_glide_friction() -> float:
	return wallGlideFriction

func get_wall_glide_gravity_curve() -> Curve:
	return wallGlideGravityCurve

func get_wall_glide_duration() -> float:
	return wallGlideDuration

func get_wall_glide_acceleration() -> float:
	return wallGlideAcceleration

func get_wall_glide_approach_speed_conv() -> float:
	return wallGlideApproachSpeedConv

func get_wall_glide_max_conv_vertical_speed() -> float:
	return wallGlideMaxConvVerticalSpeed

func get_wall_jump_speed() -> float:
	return wallJumpSpeed

func get_desired_velocity() -> Vector3:
	return desiredVelocity

func get_resolved_velocity() -> Vector3:
	return resolvedVelocity

func get_max_th_h_speed() -> float:
	return max(walkSpeed, sprintSpeed, wallGlideSpeed)

func get_hv() -> Vector2:
	return Vector2(desiredVelocity.x, desiredVelocity.z)

func set_hv(v: Vector2) -> void:
	desiredVelocity.x = v.x
	desiredVelocity.z = v.y

func get_state_name() -> String:
	return mfsml.get_state_name()

func get_previous_state_name() -> String:
	return mfsml.get_previous_state_name()

func is_on_floor() -> bool:
	return player.is_on_floor()

func is_on_ceiling() -> bool:
	return player.is_on_ceiling()
#endregion

#region Private
func _on_pmic_caught_input_event_mouse_motion(event: InputEventMouseMotion) -> void:
	player.rotate_y(-event.relative.x * sensitivity)
	var new_pitch: float = clamp(pcn.rotation.x - event.relative.y * sensitivity, minCamPitch, maxCamPitch)
	pcn.rotation.x = new_pitch

func _request_jump() -> void:
	jumpBufferTimer.start()

func _jump_requested() -> bool:
	return not jumpBufferTimer.is_stopped()

func _jump() -> void:
	jumpBufferTimer.stop()
	coyoteTimer.stop()
	_request_change_state("Jump")

func _wall_jump() -> void:
	jumpBufferTimer.stop()
	coyoteTimer.stop()
	_request_change_state("WallJump")

func _dash() -> void:
	dashCdTimer.start()
	_request_change_state("Dash")

func _airborne() -> void:
	_request_change_state("Rise" if desiredVelocity.y > 0.0 else "Fall")

func _mfsml_in_locked_state() -> bool:
	if not mfsml or not mfsml.state:
		return false
	return mfsml.state.blocks_external_transitions()

func _request_change_state(targetState: String) -> void:
	if not mfsml or not mfsml.state:
		return
	if _mfsml_in_locked_state():
		return
	mfsml.change_state(mfsml.state, targetState)

func _update_wall_contact() -> void:
	# TODO: A bug when colliding with a wall with the top slopy part of the
	# player capsule collision shape
	wallContact = false
	lastWallNormal = Vector3.ZERO
	lastWallApproachSpeed = 0.
	# Check slide collisions for walls
	var slide_count := player.get_slide_collision_count()
	for i in range(slide_count):
		var collision: KinematicCollision3D = player.get_slide_collision(i)
		if not collision:
			continue
		var normal: Vector3 = collision.get_normal()
		var ndu: float = normal.dot(Vector3.UP)
		# If the wall is vertical enough, and has a positive incline
		if ndu < wallDotUpLimit and ndu > -1e-5:
			var was: float = desiredVelocity.dot(-normal)
			if was > minWallApproachSpeed:
				# Save the normal
				lastWallNormal = normal
				# Save wall approach speed
				lastWallApproachSpeed = was
				# Start the coyote timer
				wallCoyoteTimer.start()
				wallContact = true
				break

func _update_ceiling_contact() -> void:
	if is_on_ceiling():
		desiredVelocity.y = 0.

func _handle_state_change() -> void:
	if not pmic:
		return

	# Early-out if locked (e.g., Dash)
	if _mfsml_in_locked_state():
		return

	# Cache inputs/state we query multiple times
	var jump_just_pressed := pmic.get_jump_just_pressed()
	var dash_just_pressed := pmic.get_dash_just_pressed()
	var sprint_pressed := pmic.get_sprint_pressed()
	var on_floor := is_on_floor()
	var move_dir_2d: Vector2 = get_movement_input_direction()

	# Buffer jump on press
	if jump_just_pressed:
		_request_jump()

	# Airborne logic
	if not on_floor:
		if wallContact:
			airJumpCounter = 0
			airDashCounter = 0
			coyoteTimer.start()

			# Wall jump if buffered
			if _jump_requested():
				_wall_jump()
				return

			# Hard input away from wall -> drop to airborne state
			var inputDir3: Vector3 = VectorConverter.convert_vector_2_3(move_dir_2d)
			var normal_dot_input: float = lastWallNormal.dot(inputDir3)
			if normal_dot_input > wallDisengageCos:
				_airborne()
				return

			# Stay on wall
			_request_change_state("OnWall")
			return
		else:
			# Coyote jump
			if _jump_requested() and not coyoteTimer.is_stopped():
				_jump()
				return

			# Air-jumps
			if _jump_requested() and airJumpCounter < airJumps:
				airJumpCounter += 1
				_jump()
				return
			
			if dash_just_pressed and dashCdTimer.is_stopped() and airDashCounter < airDashes:
				_dash()
				airDashCounter += 1
				return

			# Rising / Falling
			_airborne()
			return
	else: # Grounded logic
		airJumpCounter = 0
		airDashCounter = 0
		desiredVelocity.y = 0.0
		coyoteTimer.start()

		if _jump_requested():
			_jump()
			return
	
		if dash_just_pressed and dashCdTimer.is_stopped():
			_dash()
			return

		if move_dir_2d != Vector2.ZERO:
			if sprint_pressed:
				_request_change_state("Sprint")
				return
			_request_change_state("Walk")
			return

		_request_change_state("Idle")
		return
		
func _validate_required_references() -> bool:
	var valid: bool = true

	if not player:
		push_error("%s: Missing required reference 'player'." % name)
		valid = false
	if not pmic:
		push_error("%s: Missing required reference 'pmic'." % name)
		valid = false
	if not pcn:
		push_error("%s: Missing required reference 'pcn'." % name)
		valid = false
	if not mfsml:
		push_error("%s: Missing required reference 'mfsml'." % name)
		valid = false

	return valid

func _make_constant_curve(value: float) -> Curve:
	var c: Curve = Curve.new()
	c.add_point(Vector2(0.0, value))
	c.add_point(Vector2(1.0, value))
	return c

func _ensure_required_curves() -> void:
	if not dashSpeedCurve:
		push_warning("%s: dashSpeedCurve is null, using fallback constant curve." % name)
		dashSpeedCurve = _make_constant_curve(1.0)

	if not wallClingFrictionCurve:
		push_warning("%s: wallClingFrictionCurve is null, using fallback constant curve." % name)
		wallClingFrictionCurve = _make_constant_curve(1.0)

	if not wallGlideSpeedCurve:
		push_warning("%s: wallGlideSpeedCurve is null, using fallback constant curve." % name)
		wallGlideSpeedCurve = _make_constant_curve(1.0)

	if not wallGlideGravityCurve:
		push_warning("%s: wallGlideGravityCurve is null, using fallback constant curve." % name)
		wallGlideGravityCurve = _make_constant_curve(1.0)

#endregion
#endregion
