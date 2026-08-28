class_name PickupItem
extends Node3D

signal picked_up(item: Node3D)

@export_group("Interaction")
@export var display_name := "Burger"
@export var item_kind: StringName = &"burger_plate"
@export var placeable := true
@export var tooltip_height := 0.48

@export_group("Carry Pose")
@export var carry_position := Vector3(0.28, -0.30, -0.82)
@export var carry_rotation_degrees := Vector3(-7.0, -16.0, 4.0)
@export var carry_scale := Vector3(1.0, 1.0, 1.0)

var _held := false
var _interactable := true
var _world_scale := Vector3.ONE
var _tooltip: InteractionTooltip
var _collider_layers: Array[Dictionary] = []


func _ready() -> void:

	_world_scale = scale
	add_to_group("pickup_item")
	_cache_colliders(self)
	_build_tooltip()
	set_highlighted(false)


func get_tooltip_text() -> String:

	return display_name


func is_placeable() -> bool:

	return placeable


func is_held() -> bool:

	return _held


func can_interact() -> bool:

	return _interactable and not _held


func set_interactable(enabled: bool) -> void:

	_interactable = enabled
	if not _held:
		_set_colliders_enabled(enabled)
	if not enabled:
		set_highlighted(false)


func set_highlighted(enabled: bool) -> void:

	# A held terminal may reuse the silhouette as a contextual payment cue, but
	# world labels remain reserved for physical pickup objects.
	var should_outline := enabled and (can_interact() or _held)
	if _tooltip:
		_tooltip.visible = enabled and can_interact()
	var outline_controller := get_tree().get_first_node_in_group("interaction_outline_controller")
	if outline_controller and outline_controller.has_method("set_highlighted_root"):
		outline_controller.call("set_highlighted_root", self, should_outline)


func pick_up_to(carry_anchor: Node3D) -> bool:

	if not can_interact() or carry_anchor == null:
		return false
	set_highlighted(false)
	reparent(carry_anchor, false)
	position = carry_position
	rotation_degrees = carry_rotation_degrees
	scale = carry_scale
	_held = true
	_set_colliders_enabled(false)
	picked_up.emit(self)
	return true


func place_on(slot: Node3D, interactable_after_place := false) -> bool:

	if slot == null or not _held:
		return false
	reparent(slot, false)
	transform = Transform3D.IDENTITY
	scale = _world_scale
	_held = false
	set_interactable(interactable_after_place)
	return true


func set_burger_visible(value: bool) -> void:

	var burger := get_node_or_null("Burger") as Node3D
	if burger:
		burger.visible = value
	if not value:
		display_name = "Plate"
		item_kind = &"empty_plate"
		placeable = false


func _build_tooltip() -> void:

	_tooltip = InteractionTooltip.create_label(&"WorldTooltip", display_name, tooltip_height)
	add_child(_tooltip)
	_tooltip.follow_target(self, tooltip_height)


func _cache_colliders(node: Node) -> void:

	for child in node.get_children():
		if child is CollisionObject3D:
			_collider_layers.append({
				"node": child,
				"layer": child.collision_layer,
				"mask": child.collision_mask,
			})
		_cache_colliders(child)


func _set_colliders_enabled(enabled: bool) -> void:

	for entry in _collider_layers:
		var collider := entry["node"] as CollisionObject3D
		if collider == null:
			continue
		collider.collision_layer = entry["layer"] if enabled else 0
		collider.collision_mask = entry["mask"] if enabled else 0
