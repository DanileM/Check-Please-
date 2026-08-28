class_name InteractionTooltip
extends Label3D

# Shared world-label language. Keep these values here so physical interaction
# targets never acquire per-scene typography or scale rules.
const TOOLTIP_FONT_SIZE := 22
const TOOLTIP_OUTLINE_SIZE := 4
const TOOLTIP_PIXEL_SIZE := 0.0035
const TOOLTIP_COLOR := Color("#fff0c8")
const TOOLTIP_OUTLINE_COLOR := Color("#2a202c")
const TOOLTIP_OBJECT_MARGIN := 0.08

var _follow_target: Node3D
var _follow_height := 0.0
var _follow_visual_bounds := false
var _visual_meshes: Array[MeshInstance3D] = []


static func create_label(label_name: StringName, label_text: String, local_height: float = 0.0) -> InteractionTooltip:
	var tooltip := InteractionTooltip.new()
	tooltip.name = label_name
	tooltip._follow_height = local_height
	tooltip.text = label_text
	tooltip.font_size = TOOLTIP_FONT_SIZE
	tooltip.outline_size = TOOLTIP_OUTLINE_SIZE
	tooltip.pixel_size = TOOLTIP_PIXEL_SIZE
	tooltip.modulate = TOOLTIP_COLOR
	tooltip.outline_modulate = TOOLTIP_OUTLINE_COLOR
	tooltip.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	tooltip.fixed_size = true
	tooltip.no_depth_test = true
	tooltip.visible = false
	return tooltip


func follow_target(target: Node3D, local_height: float = _follow_height) -> void:
	_follow_target = target
	_follow_height = local_height
	_follow_visual_bounds = false
	_visual_meshes.clear()
	top_level = true
	# Detach both transform inheritance and the scale captured when Label3D was
	# parented, so a 3D prop's import scale cannot enlarge its world text.
	scale = Vector3.ONE
	_sync_position()


func follow_visual_bounds(target: Node3D) -> void:
	_follow_target = target
	_follow_visual_bounds = true
	_visual_meshes.clear()
	_cache_visual_meshes(target)
	top_level = true
	scale = Vector3.ONE
	_sync_position()


func _process(_delta: float) -> void:
	_sync_position()


func _sync_position() -> void:
	if _follow_target == null or not is_instance_valid(_follow_target):
		return
	if _follow_visual_bounds:
		var bounds_anchor := get_visual_bounds_top_center()
		if bounds_anchor.is_finite():
			global_position = bounds_anchor + Vector3.UP * TOOLTIP_OBJECT_MARGIN
			return
	global_position = _follow_target.to_global(Vector3(0.0, _follow_height, 0.0))


func get_visual_bounds_top_center() -> Vector3:
	var minimum := Vector3.INF
	var maximum := -Vector3.INF
	var has_bounds := false
	for mesh in _visual_meshes:
		if mesh == null or not is_instance_valid(mesh) or mesh.mesh == null or not mesh.is_visible_in_tree():
			continue
		var local_bounds := mesh.mesh.get_aabb()
		for x in [local_bounds.position.x, local_bounds.end.x]:
			for y in [local_bounds.position.y, local_bounds.end.y]:
				for z in [local_bounds.position.z, local_bounds.end.z]:
					var point := mesh.to_global(Vector3(x, y, z))
					minimum = minimum.min(point)
					maximum = maximum.max(point)
					has_bounds = true
	if not has_bounds:
		return Vector3(NAN, NAN, NAN)
	return Vector3((minimum.x + maximum.x) * 0.5, maximum.y, (minimum.z + maximum.z) * 0.5)


func _cache_visual_meshes(node: Node) -> void:
	if node is MeshInstance3D:
		_visual_meshes.append(node)
	for child in node.get_children():
		_cache_visual_meshes(child)
