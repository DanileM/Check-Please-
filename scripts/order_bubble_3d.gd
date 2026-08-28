class_name OrderBubble3D
extends Node3D

@export_group("World Presentation")
@export var viewport_size := Vector2i(250, 154)
@export var world_pixel_size := 0.0030
@export var float_height := 0.022
@export var float_frequency := 1.25
@export var fade_speed := 5.0
@export var shake_distance := 0.014
@export var shake_frequency := 19.0

var _viewport: SubViewport
var _canvas: BubbleCanvas
var _icon_row: HBoxContainer
var _sprite: Sprite3D
var _visibility_progress := 0.0
var _target_visibility := 0.0
var _shaking := false
var _time := 0.0
var _base_sprite_position := Vector3.ZERO
var _order_icons := PackedStringArray()

const BURGER_ICON := preload("res://assets/ui/icons/burger_order.png")
const PAYMENT_ICON := preload("res://assets/ui/icons/banknote_payment.png")


func _ready() -> void:

	_build_display()
	visible = false


func show_order(icon_ids: PackedStringArray = PackedStringArray(["burger"])) -> void:

	_order_icons = icon_ids.slice(0, 5)
	if _order_icons.is_empty():
		hide_order()
		return
	_rebuild_icon_slots()
	_set_viewport_active(true)
	_target_visibility = 1.0
	visible = true


func hide_order() -> void:

	_target_visibility = 0.0
	_shaking = false


func set_shaking(enabled: bool) -> void:

	_shaking = enabled


func is_order_visible() -> bool:

	return _target_visibility > 0.0 or _visibility_progress > 0.001


func is_shaking() -> bool:

	return _shaking


func get_visual_offset() -> Vector3:

	return _sprite.position - _base_sprite_position if _sprite else Vector3.ZERO


func get_order_icons() -> PackedStringArray:

	return _order_icons


func _process(delta: float) -> void:

	if _sprite == null:
		return
	_time += delta
	_visibility_progress = move_toward(_visibility_progress, _target_visibility, fade_speed * delta)
	_sprite.modulate.a = _visibility_progress
	_canvas.set_reveal(_visibility_progress)

	var float_offset := Vector3(0.0, sin(_time * float_frequency * TAU) * float_height, 0.0)
	var shake_offset := Vector3.ZERO
	if _shaking:
		shake_offset = Vector3(
			sin(_time * shake_frequency) * shake_distance,
			cos(_time * shake_frequency * 1.21) * shake_distance * 0.35,
			0.0
		)
	_sprite.position = _base_sprite_position + float_offset + shake_offset
	if _target_visibility <= 0.0 and _visibility_progress <= 0.001:
		visible = false
		_set_viewport_active(false)


func _build_display() -> void:

	_viewport = SubViewport.new()
	_viewport.name = "OrderBubbleViewport"
	_viewport.size = viewport_size
	_viewport.transparent_bg = true
	_viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
	add_child(_viewport)

	_canvas = BubbleCanvas.new()
	_canvas.name = "BubbleCanvas"
	_canvas.size = Vector2(viewport_size)
	_viewport.add_child(_canvas)

	_icon_row = HBoxContainer.new()
	_icon_row.name = "IconSlots"
	# Center icons inside the rounded bubble body, excluding its lower tail.
	_icon_row.position = Vector2(35.0, 24.0)
	_icon_row.size = Vector2(viewport_size.x - 70.0, 76.0)
	_icon_row.alignment = BoxContainer.ALIGNMENT_CENTER
	_icon_row.add_theme_constant_override("separation", 6)
	_canvas.add_child(_icon_row)

	_sprite = Sprite3D.new()
	_sprite.name = "OrderBubbleSprite"
	_sprite.texture = _viewport.get_texture()
	_sprite.pixel_size = world_pixel_size
	_sprite.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_sprite.no_depth_test = true
	add_child(_sprite)
	_base_sprite_position = _sprite.position
	_sprite.modulate.a = 0.0
	_rebuild_icon_slots()
	_set_viewport_active(false)


func _rebuild_icon_slots() -> void:

	if _icon_row == null:
		return
	for child in _icon_row.get_children():
		child.queue_free()
	for icon_id in _order_icons:
		var slot := TextureRect.new()
		slot.name = "%sIcon" % icon_id.capitalize()
		slot.texture = _get_icon_texture(icon_id)
		slot.custom_minimum_size = Vector2(76.0, 76.0)
		slot.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		slot.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		_icon_row.add_child(slot)


func _get_icon_texture(icon_id: String) -> Texture2D:

	return PAYMENT_ICON if icon_id == "payment" else BURGER_ICON


func _set_viewport_active(active: bool) -> void:
	if _viewport:
		_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS if active else SubViewport.UPDATE_DISABLED
	set_process(active)


class BubbleCanvas extends Control:
	var reveal := 0.0

	func set_reveal(value: float) -> void:
		reveal = clampf(value, 0.0, 1.0)
		queue_redraw()

	func _draw() -> void:
		var border := Color("#30242d")
		var background := Color("#fff1cf")
		var accent := Color("#f4ce61")
		var box := StyleBoxFlat.new()
		box.bg_color = background
		box.border_color = border
		box.set_border_width_all(7)
		box.set_corner_radius_all(38)
		var bubble_rect := Rect2(8.0, 4.0, size.x - 16.0, size.y - 35.0)
		draw_style_box(box, bubble_rect)
		var fill_top := lerpf(size.y - 40.0, 24.0, reveal)
		draw_rect(Rect2(17.0, fill_top, size.x - 34.0, size.y - 50.0 - fill_top), Color(accent, 0.23))
		var tail := PackedVector2Array([
			Vector2(size.x * 0.5 - 15.0, bubble_rect.end.y - 4.0),
			Vector2(size.x * 0.5 + 18.0, bubble_rect.end.y - 4.0),
			Vector2(size.x * 0.5 + 4.0, size.y - 4.0),
		])
		# Overlap the lower border and draw only the tail's exposed sides so the
		# bubble reads as one continuous silhouette instead of two joined shapes.
		draw_colored_polygon(tail, background)
		draw_polyline(PackedVector2Array([tail[0], tail[2], tail[1]]), border, 7.0, true)
