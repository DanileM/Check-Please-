extends Node3D

@export var customer_seating_enabled := true

@onready var customer := get_node_or_null("Customer") as CustomerController
@onready var station := get_node_or_null("Restaurant/TableStations/TableStationA") as TableStation
@onready var entry := get_node_or_null("Restaurant/CustomerMarkers/Entry") as Marker3D
@onready var exit := get_node_or_null("Restaurant/CustomerMarkers/Exit") as Marker3D
@onready var player_camera := get_node_or_null("Player/Head/Camera3D") as Camera3D
@onready var player := get_node_or_null("Player") as Node3D

func _ready() -> void:
    if not customer_seating_enabled or customer == null or station == null or entry == null:
        _disable_customer()
        return

    customer.set_head_look_target(player_camera)
    if player:
        player.call("set_payment_customer", customer)
    customer.configure(station, entry, exit)
    customer.seating_state_changed.connect(_on_customer_state_changed)
    station.food_placed.connect(_on_food_placed)
    station.set_food_delivery_allowed(false)
    customer.start_seating_sequence()


func _on_customer_state_changed(_state_name: StringName) -> void:
    if customer and station:
        station.set_food_delivery_allowed(customer.can_accept_food())


func _on_food_placed(food: Node3D) -> void:
    if customer == null or not customer.accept_delivered_food(food):
        if station:
            station.enable_empty_plate_pickup()


func _disable_customer() -> void:
    if customer == null:
        return
    customer.visible = false
    customer.process_mode = Node.PROCESS_MODE_DISABLED
    customer.collision_layer = 0
    customer.collision_mask = 0
