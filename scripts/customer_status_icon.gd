class_name CustomerStatusIcon
extends Node3D

@export var viewport_size := Vector2i(180, 144)
@export var world_pixel_size := 0.0032
@export var shake_distance := 0.018
@export var shake_frequency := 22.0
@export var bob_height := 0.026
@export var bob_frequency := 1.65

var _viewport: SubViewport
var _background_label: Label
var _fill_clip: Control
var _fill_label: Label
var _sprite: Sprite3D
var _symbol := "!"
var _fill_progress := 0.0
var _shaking := false
var _shake_time := 0.0
var _bob_time := 0.0
var _base_sprite_position := Vector3.ZERO


func _ready() -> void:
	_build_display()
	hide_icon()


func show_icon(symbol: String) -> void:
	_symbol = symbol
	_bob_time = 0.0
	_apply_symbol()
	visible = true


func hide_icon() -> void:
	_shaking = false
	_shake_time = 0.0
	_bob_time = 0.0
	if _sprite:
		_sprite.position = _base_sprite_position
	visible = false


func set_fill_progress(progress: float) -> void:
	_fill_progress = clampf(progress, 0.0, 1.0)
	_apply_fill()


func set_shaking(enabled: bool) -> void:
	_shaking = enabled
	if not _shaking and _sprite:
		_sprite.position = _base_sprite_position


func get_symbol() -> String:
	return _symbol


func get_fill_progress() -> float:
	return _fill_progress


func is_shaking() -> bool:
	return _shaking


func get_visual_offset() -> Vector3:
	return _sprite.position - _base_sprite_position if _sprite else Vector3.ZERO


func _process(delta: float) -> void:
	if _sprite == null:
		return
	_bob_time += delta
	var bob_offset := Vector3(0.0, sin(_bob_time * bob_frequency * TAU) * bob_height, 0.0)
	var shake_offset := Vector3.ZERO
	if _shaking:
		_shake_time += delta
		shake_offset = Vector3(
			sin(_shake_time * shake_frequency) * shake_distance,
			cos(_shake_time * shake_frequency * 1.37) * shake_distance * 0.45,
			0.0
		)
	_sprite.position = _base_sprite_position + bob_offset + shake_offset


func _build_display() -> void:
	_viewport = SubViewport.new()
	_viewport.name = "StatusViewport"
	_viewport.size = viewport_size
	_viewport.transparent_bg = true
	_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(_viewport)

	var canvas := Control.new()
	canvas.name = "Canvas"
	canvas.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_viewport.add_child(canvas)

	_background_label = _make_label(Color(1.0, 0.92, 0.61, 0.20))
	canvas.add_child(_background_label)

	_fill_clip = Control.new()
	_fill_clip.name = "FillClip"
	_fill_clip.clip_contents = true
	canvas.add_child(_fill_clip)

	_fill_label = _make_label(Color(1.0, 0.88, 0.30, 1.0))
	_fill_clip.add_child(_fill_label)

	_sprite = Sprite3D.new()
	_sprite.name = "StatusSprite"
	_sprite.texture = _viewport.get_texture()
	_sprite.pixel_size = world_pixel_size
	_sprite.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_sprite.no_depth_test = true
	add_child(_sprite)
	_base_sprite_position = _sprite.position

	_apply_symbol()
	_apply_fill()


func _make_label(color: Color) -> Label:
	var label := Label.new()
	label.position = Vector2.ZERO
	label.size = Vector2(viewport_size)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 108)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", Color(0.12, 0.06, 0.08, 0.92))
	label.add_theme_constant_override("outline_size", 8)
	return label


func _apply_symbol() -> void:
	var font_size := 108 if _symbol.length() <= 2 else 58
	if _background_label:
		_background_label.add_theme_font_size_override("font_size", font_size)
	if _fill_label:
		_fill_label.add_theme_font_size_override("font_size", font_size)
	if _background_label:
		_background_label.text = _symbol
	if _fill_label:
		_fill_label.text = _symbol


func _apply_fill() -> void:
	if _fill_clip == null or _fill_label == null:
		return
	var full_size := Vector2(viewport_size)
	var clipped_height := full_size.y * _fill_progress
	var top_offset := full_size.y - clipped_height
	_fill_clip.position = Vector2(0.0, top_offset)
	_fill_clip.size = Vector2(full_size.x, clipped_height)
	_fill_label.position = Vector2(0.0, -top_offset)
	_fill_label.size = full_size
