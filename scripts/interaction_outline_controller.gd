class_name InteractionOutlineController
extends Node

const MASK_LAYER := 1 << 19
const OUTLINE_SHADER := preload("res://shaders/interaction_outline.gdshader")

@export var source_camera_path: NodePath
@export var outline_color := Color("#f8d351")
@export_range(0.5, 3.0, 0.05) var outline_width_pixels := 1.35

var _source_camera: Camera3D
var _mask_viewport: SubViewport
var _mask_camera: Camera3D
var _mask_root: Node3D
var _overlay: TextureRect
var _mask_material: StandardMaterial3D
var _highlighted_root: Node3D
var _mask_pairs: Array[Dictionary] = []
var _last_viewport_size := Vector2i.ZERO


func _ready() -> void:
	add_to_group("interaction_outline_controller")
	_source_camera = get_node_or_null(source_camera_path) as Camera3D
	if _source_camera == null:
		push_warning("Interaction outline disabled: source camera is missing")
		return
	_source_camera.cull_mask &= ~MASK_LAYER
	_build_mask_viewport()
	_set_mask_viewport_active(false)


func _exit_tree() -> void:
	if _source_camera:
		_source_camera.cull_mask |= MASK_LAYER


func set_highlighted_root(root: Node3D, enabled: bool) -> void:
	if not enabled:
		if root == _highlighted_root:
			_clear_highlight()
		return
	if root == null or not is_instance_valid(root):
		_clear_highlight()
		return
	if root != _highlighted_root:
		_highlighted_root = root
		_rebuild_mask_meshes()
	_set_mask_viewport_active(not _mask_pairs.is_empty())
	if _overlay:
		_overlay.visible = not _mask_pairs.is_empty()


func _process(_delta: float) -> void:
	if _source_camera == null or _mask_camera == null:
		return
	_mask_camera.global_transform = _source_camera.global_transform
	_mask_camera.fov = _source_camera.fov
	_mask_camera.near = _source_camera.near
	_mask_camera.far = _source_camera.far
	_sync_viewport_size()
	_sync_mask_meshes()


func _build_mask_viewport() -> void:
	_mask_viewport = SubViewport.new()
	_mask_viewport.name = "InteractionOutlineMaskViewport"
	_mask_viewport.transparent_bg = true
	_mask_viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
	_mask_viewport.world_3d = get_viewport().world_3d
	add_child(_mask_viewport)

	_mask_root = Node3D.new()
	_mask_root.name = "InteractionOutlineMaskRoot"
	_mask_viewport.add_child(_mask_root)
	_mask_camera = Camera3D.new()
	_mask_camera.name = "InteractionOutlineMaskCamera"
	_mask_camera.cull_mask = MASK_LAYER
	_mask_camera.current = true
	_mask_root.add_child(_mask_camera)

	var overlay_layer := CanvasLayer.new()
	overlay_layer.name = "InteractionOutlineOverlay"
	overlay_layer.layer = 2
	add_child(overlay_layer)
	_overlay = TextureRect.new()
	_overlay.name = "SelectionSilhouette"
	_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_overlay.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_overlay.texture = _mask_viewport.get_texture()
	var material := ShaderMaterial.new()
	material.shader = OUTLINE_SHADER
	material.set_shader_parameter("outline_color", outline_color)
	material.set_shader_parameter("outline_width_pixels", outline_width_pixels)
	material.set_shader_parameter("mask_texture", _mask_viewport.get_texture())
	_overlay.material = material
	_overlay.visible = false
	overlay_layer.add_child(_overlay)
	_sync_viewport_size()


func _sync_viewport_size() -> void:
	if _mask_viewport == null:
		return
	var size := Vector2i(get_viewport().get_visible_rect().size)
	if size == _last_viewport_size or size.x <= 0 or size.y <= 0:
		return
	_last_viewport_size = size
	_mask_viewport.size = size


func _rebuild_mask_meshes() -> void:
	for pair in _mask_pairs:
		var mask_mesh := pair.get("mask") as MeshInstance3D
		if mask_mesh and is_instance_valid(mask_mesh):
			mask_mesh.queue_free()
	_mask_pairs.clear()
	if _highlighted_root == null or not is_instance_valid(_highlighted_root) or _mask_root == null:
		return
	for source_mesh in _find_meshes(_highlighted_root):
		if source_mesh.mesh == null:
			continue
		var mask_mesh := MeshInstance3D.new()
		mask_mesh.name = "Mask_%s" % source_mesh.name
		mask_mesh.mesh = source_mesh.mesh
		mask_mesh.layers = MASK_LAYER
		mask_mesh.material_override = _get_mask_material()
		mask_mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		_mask_root.add_child(mask_mesh)
		_mask_pairs.append({"source": source_mesh, "mask": mask_mesh})
	_sync_mask_meshes()


func _sync_mask_meshes() -> void:
	for pair in _mask_pairs:
		var source_mesh := pair.get("source") as MeshInstance3D
		var mask_mesh := pair.get("mask") as MeshInstance3D
		if mask_mesh == null or not is_instance_valid(mask_mesh):
			continue
		var visible := source_mesh != null and is_instance_valid(source_mesh) and source_mesh.is_visible_in_tree()
		mask_mesh.visible = visible
		if visible:
			mask_mesh.global_transform = source_mesh.global_transform


func _clear_highlight() -> void:
	_highlighted_root = null
	_rebuild_mask_meshes()
	_set_mask_viewport_active(false)
	if _overlay:
		_overlay.visible = false


func _set_mask_viewport_active(active: bool) -> void:
	if _mask_viewport:
		_mask_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS if active else SubViewport.UPDATE_DISABLED
	set_process(active)


func _get_mask_material() -> StandardMaterial3D:
	if _mask_material == null:
		_mask_material = StandardMaterial3D.new()
		_mask_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		_mask_material.albedo_color = Color.WHITE
		_mask_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	return _mask_material


func _find_meshes(node: Node) -> Array[MeshInstance3D]:
	var meshes: Array[MeshInstance3D] = []
	for child in node.get_children():
		if child is MeshInstance3D:
			meshes.append(child)
		meshes.append_array(_find_meshes(child))
	return meshes
