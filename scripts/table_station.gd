class_name TableStation
extends Node3D

@export var table_id := 1

@onready var approach_point: Marker3D = $ApproachPoint
@onready var seat_point: Marker3D = $SeatPoint
@onready var waiter_point: Marker3D = $WaiterPoint
@onready var food_slot: Marker3D = $FoodSlot
@onready var drink_slot: Marker3D = $DrinkSlot

func _ready() -> void:
    add_to_group("table_station")
