extends Node3D

@export var customer_seating_enabled := true

@onready var customer := get_node_or_null("Customer") as CustomerController
@onready var station := get_node_or_null("Restaurant/TableStations/TableStationA") as TableStation
@onready var entry := get_node_or_null("Restaurant/CustomerMarkers/Entry") as Marker3D
@onready var exit := get_node_or_null("Restaurant/CustomerMarkers/Exit") as Marker3D
@onready var player_camera := get_node_or_null("Player/Head/Camera3D") as Camera3D

func _ready() -> void:
    if not customer_seating_enabled or customer == null or station == null or entry == null:
        _disable_customer()
        return

    customer.set_head_look_target(player_camera)
    customer.configure(station, entry, exit)
    customer.start_seating_sequence()


func _disable_customer() -> void:
    if customer == null:
        return
    customer.visible = false
    customer.process_mode = Node.PROCESS_MODE_DISABLED
    customer.collision_layer = 0
    customer.collision_mask = 0
