class_name InteractionTooltip
extends Label3D

# Shared world-label language. Keep these values here so physical interaction
# targets never acquire per-scene typography or scale rules.
const TOOLTIP_FONT_SIZE := 26
const TOOLTIP_OUTLINE_SIZE := 5
const TOOLTIP_PIXEL_SIZE := 0.0035
const TOOLTIP_COLOR := Color("#fff0c8")
const TOOLTIP_OUTLINE_COLOR := Color("#2a202c")


static func create_label(label_name: StringName, label_text: String, local_height: float) -> InteractionTooltip:
	var tooltip := InteractionTooltip.new()
	tooltip.name = label_name
	tooltip.position = Vector3(0.0, local_height, 0.0)
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
