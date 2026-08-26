class_name ComicStyle
extends RefCounted

const OUTLINE_SHADER := preload("res://shaders/pencil_outline.gdshader")

static func apply(root: Node, width: float = 0.014) -> void:
    _apply_recursive(root, width)

static func _apply_recursive(node: Node, width: float) -> void:
    if node is MeshInstance3D:
        var outline := ShaderMaterial.new()
        outline.shader = OUTLINE_SHADER
        outline.set_shader_parameter("outline_width", width)
        node.material_overlay = outline
        node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
    for child in node.get_children():
        _apply_recursive(child, width)
