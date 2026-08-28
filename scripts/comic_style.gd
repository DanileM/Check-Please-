class_name ComicStyle
extends RefCounted

const OUTLINE_SHADER := preload("res://shaders/pencil_outline.gdshader")

static func apply(root: Node, width: float = 0.014, minimum_outline_extent := 0.0) -> void:
	_apply_recursive(root, width, minimum_outline_extent)

static func _apply_recursive(node: Node, width: float, minimum_outline_extent: float) -> void:
	if node.is_in_group("comic_outline_exempt"):
		return
	if node is MeshInstance3D:
		if _should_outline(node, minimum_outline_extent):
			var outline := ShaderMaterial.new()
			outline.shader = OUTLINE_SHADER
			outline.set_shader_parameter("outline_width", width)
			node.material_overlay = outline
	for child in node.get_children():
		_apply_recursive(child, width, minimum_outline_extent)


static func _should_outline(mesh: MeshInstance3D, minimum_outline_extent: float) -> bool:
	if mesh.is_in_group("comic_outline_detail"):
		return false
	if mesh.is_in_group("comic_outline_force"):
		return true
	if mesh.mesh == null or minimum_outline_extent <= 0.0:
		return mesh.mesh != null
	var bounds_size := mesh.mesh.get_aabb().size * mesh.global_transform.basis.get_scale().abs()
	var largest_extent := maxf(bounds_size.x, maxf(bounds_size.y, bounds_size.z))
	return largest_extent >= minimum_outline_extent
