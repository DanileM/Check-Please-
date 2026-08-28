class_name TableStation
extends Node3D

signal food_placed(item: Node3D)
signal empty_plate_collected

@export var table_id := 1
@export var place_tooltip_height := 1.34
@export var highlight_outline_width := 0.018

@onready var approach_point: Marker3D = $ApproachPoint
@onready var seat_point: Marker3D = $SeatPoint
@onready var exit_point: Marker3D = get_node_or_null("ExitPoint") as Marker3D
@onready var look_point: Marker3D = $LookPoint
@onready var waiter_point: Marker3D = $WaiterPoint
@onready var food_slot: Marker3D = $FoodSlot
@onready var drink_slot: Marker3D = $DrinkSlot
@onready var table_visual: Node3D = $Table

var food_delivery_allowed := false
var placed_item: Node3D
var _tooltip: InteractionTooltip

func _ready() -> void:
    add_to_group("table_station")
    _build_tooltip()
    set_place_highlighted(false)


func set_food_delivery_allowed(enabled: bool) -> void:
    food_delivery_allowed = enabled
    if not enabled:
        set_place_highlighted(false)


func can_place_item(item: Node3D) -> bool:
    return (
        food_delivery_allowed
        and placed_item == null
        and item != null
        and item.has_method("is_placeable")
        and item.call("is_placeable")
    )


func get_tooltip_text() -> String:
    return "Table"


func set_place_highlighted(enabled: bool) -> void:
    var should_show := enabled and food_delivery_allowed and placed_item == null
    if _tooltip:
        _tooltip.visible = should_show
    var outline_controller := get_tree().get_first_node_in_group("interaction_outline_controller")
    if outline_controller and outline_controller.has_method("set_highlighted_root"):
        outline_controller.call("set_highlighted_root", table_visual, should_show)


func place_item(item: Node3D) -> bool:
    if not can_place_item(item):
        return false
    if not item.call("place_on", food_slot, false):
        return false
    placed_item = item
    food_delivery_allowed = false
    set_place_highlighted(false)
    if item.has_signal("picked_up") and not item.picked_up.is_connected(_on_placed_item_picked_up):
        item.picked_up.connect(_on_placed_item_picked_up)
    food_placed.emit(item)
    return true


func enable_empty_plate_pickup() -> void:
    if placed_item and placed_item.has_method("set_interactable"):
        placed_item.call("set_interactable", true)


func _on_placed_item_picked_up(item: Node3D) -> void:
    if item != placed_item:
        return
    placed_item = null
    empty_plate_collected.emit()


func _build_tooltip() -> void:
    _tooltip = InteractionTooltip.create_label(&"PlaceTooltip", "Table", place_tooltip_height)
    add_child(_tooltip)
    _tooltip.follow_target(self, place_tooltip_height)
