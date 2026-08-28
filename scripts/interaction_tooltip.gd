class_name InteractionTooltip
extends Label3D

# Shared world-label language. Keep these values here so physical interaction
# targets never acquire per-scene typography or scale rules.
const TOOLTIP_FONT_SIZE := 26
const TOOLTIP_OUTLINE_SIZE := 5
const TOOLTIP_PIXEL_SIZE := 0.0035
const TOOLTIP_COLOR := Color("#fff0c8")
const TOOLTIP_OUTLINE_COLOR := Color("#2a202c")

var _follow_target: Node3D
var _follow_height := 0.0


static func create_label(label_name: StringName, label_text: String, local_height: float) -> InteractionTooltip:
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
	top_level = true
	# Detach both transform inheritance and the scale captured when Label3D was
	# parented, so a 3D prop's import scale cannot enlarge its world text.
	scale = Vector3.ONE
	_sync_position()


func _process(_delta: float) -> void:
	_sync_position()


func _sync_position() -> void:
	if _follow_target and is_instance_valid(_follow_target):
		global_position = _follow_target.to_global(Vector3(0.0, _follow_height, 0.0))
