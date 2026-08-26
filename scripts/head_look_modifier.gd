class_name HeadLookModifier
extends SkeletonModifier3D

const HEAD_BONE_NAME: StringName = &"Head_2"
const MAX_HEAD_YAW_DEG := 55.0
const MAX_LOOK_UP_DEG := 25.0
const MAX_LOOK_DOWN_DEG := 30.0
const TRACKING_CONE_YAW_DEG := 85.0
const MAX_LOOK_DISTANCE := 8.0
const LOOK_IN_SPEED := 7.0
const LOOK_OUT_SPEED := 5.0

var _head_bone_name := HEAD_BONE_NAME
var _head_bone_index := -1
var _head_parent_bone_index := -1
var _look_target: Node3D
var _head_look_enabled := false
var _tracking_target := false
var _current_yaw := 0.0
var _current_pitch := 0.0
var _last_animated_rotation := Quaternion.IDENTITY
var _last_applied_rotation := Quaternion.IDENTITY


func configure(head_bone_name: StringName = HEAD_BONE_NAME) -> void:
	_head_bone_name = HEAD_BONE_NAME if head_bone_name == &"" else head_bone_name
	_head_bone_index = -1
	_head_parent_bone_index = -1
	_resolve_head_bone()


func set_head_look_target(target: Node3D) -> void:
	_look_target = target


func set_head_look_enabled(enabled: bool) -> void:
	_head_look_enabled = enabled


func get_current_yaw_degrees() -> float:
	return rad_to_deg(_current_yaw)


func get_current_pitch_degrees() -> float:
	return rad_to_deg(_current_pitch)


func is_tracking_target() -> bool:
	return _tracking_target


func is_head_look_enabled() -> bool:
	return _head_look_enabled


func get_last_animated_head_rotation() -> Quaternion:
	return _last_animated_rotation


func get_last_applied_head_rotation() -> Quaternion:
	return _last_applied_rotation


func _validate_bone_names() -> void:
	_resolve_head_bone()


func _process_modification_with_delta(delta: float) -> void:
	var skeleton := get_skeleton()
	if skeleton == null:
		_tracking_target = false
		return
	if _head_bone_index < 0 and not _resolve_head_bone():
		_tracking_target = false
		return

	_last_animated_rotation = skeleton.get_bone_pose_rotation(_head_bone_index)
	var target_angles := _calculate_target_angles(skeleton)
	var smoothing_speed := LOOK_IN_SPEED if _tracking_target else LOOK_OUT_SPEED
	if delta > 0.0:
		var smoothing_weight := 1.0 - exp(-smoothing_speed * delta)
		_current_yaw = lerp(_current_yaw, target_angles.x, smoothing_weight)
		_current_pitch = lerp(_current_pitch, target_angles.y, smoothing_weight)

	var yaw_offset := Quaternion(Vector3.UP, _current_yaw)
	var pitch_offset := Quaternion(Vector3.RIGHT, _current_pitch)
	var procedural_offset := (yaw_offset * pitch_offset).normalized()
	_last_applied_rotation = (procedural_offset * _last_animated_rotation).normalized()
	skeleton.set_bone_pose_rotation(_head_bone_index, _last_applied_rotation)


func _calculate_target_angles(skeleton: Skeleton3D) -> Vector2:
	_tracking_target = false
	if not _head_look_enabled or not is_instance_valid(_look_target):
		return Vector2.ZERO

	var head_pose := skeleton.get_bone_global_pose(_head_bone_index)
	var head_world_position := skeleton.global_transform * head_pose.origin
	if head_world_position.distance_to(_look_target.global_position) > MAX_LOOK_DISTANCE:
		return Vector2.ZERO

	var parent_pose := Transform3D.IDENTITY
	if _head_parent_bone_index >= 0:
		parent_pose = skeleton.get_bone_global_pose(_head_parent_bone_index)
	var target_skeleton_position := skeleton.to_local(_look_target.global_position)
	var head_parent_position := parent_pose.affine_inverse() * head_pose.origin
	var target_parent_position := parent_pose.affine_inverse() * target_skeleton_position
	var local_direction := target_parent_position - head_parent_position
	if local_direction.length_squared() < 0.000001:
		return Vector2.ZERO
	local_direction = local_direction.normalized()

	var raw_yaw := atan2(-local_direction.x, -local_direction.z)
	if absf(raw_yaw) > deg_to_rad(TRACKING_CONE_YAW_DEG):
		return Vector2.ZERO

	var horizontal_length := Vector2(local_direction.x, local_direction.z).length()
	var raw_pitch := atan2(local_direction.y, horizontal_length)
	_tracking_target = true
	return Vector2(
		clampf(raw_yaw, -deg_to_rad(MAX_HEAD_YAW_DEG), deg_to_rad(MAX_HEAD_YAW_DEG)),
		clampf(raw_pitch, -deg_to_rad(MAX_LOOK_DOWN_DEG), deg_to_rad(MAX_LOOK_UP_DEG))
	)


func _resolve_head_bone() -> bool:
	var skeleton := get_skeleton()
	if skeleton == null:
		return false
	_head_bone_index = skeleton.find_bone(_head_bone_name)
	if _head_bone_index < 0:
		_head_parent_bone_index = -1
		return false
	_head_parent_bone_index = skeleton.get_bone_parent(_head_bone_index)
	return true
