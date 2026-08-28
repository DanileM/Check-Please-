extends CharacterBody3D

@export var move_speed := 4.2
@export var mouse_sensitivity := 0.0022
@export var acceleration := 14.0

@export_group("Interaction Ranges")
@export var world_pickup_distance := 7.5
@export var held_item_action_distance := 3.0
@export var payment_action_distance := 3.0

@export_group("Held Item Collision")
@export_range(0.005, 0.08, 0.005) var held_item_wall_padding := 0.025
@export var held_item_restore_speed := 8.0
@export_flags_3d_physics var held_item_obstacle_mask := 1

@onready var head: Node3D = $Head
@onready var camera: Camera3D = $Head/Camera3D
@onready var ray: RayCast3D = $Head/Camera3D/InteractRay
@onready var carry_anchor: Node3D = $Head/Camera3D/CarryAnchor
@onready var hint: Label = $HUD/Hint

var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var held_item: Node3D
var interaction_target: Node
var payment_customer: Node3D
var payment_terminal: Node3D
var payment_mode := false
var _held_item_query := PhysicsShapeQueryParameters3D.new()

func _ready() -> void:
    Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
    hint.text = "WASD — move    E — pick up    ESC — mouse"
    ray.target_position.z = -world_pickup_distance

func _unhandled_input(event: InputEvent) -> void:
    if payment_mode:
        if event is InputEventMouseButton and event.is_action_pressed(&"use_held_item"):
            if payment_terminal:
                payment_terminal.call("click_from_camera", camera, event.position)
        elif event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
            end_payment_mode()
        return
    if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
        rotate_y(-event.relative.x * mouse_sensitivity)
        head.rotate_x(-event.relative.y * mouse_sensitivity)
        head.rotation.x = clamp(head.rotation.x, deg_to_rad(-82.0), deg_to_rad(82.0))
    elif event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
        Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED else Input.MOUSE_MODE_CAPTURED
    elif event is InputEventMouseButton and event.is_action_pressed(&"use_held_item"):
        if _use_held_item():
            get_viewport().set_input_as_handled()
        elif Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
            Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
    elif event.is_action_pressed(&"interact_pickup"):
        _interact()

func _physics_process(delta: float) -> void:
    if payment_mode:
        velocity = Vector3.ZERO
        _set_interaction_target(null)
        _update_held_item_retraction(delta)
        return
    var input_vec := Vector2.ZERO
    if Input.is_physical_key_pressed(KEY_A): input_vec.x -= 1.0
    if Input.is_physical_key_pressed(KEY_D): input_vec.x += 1.0
    if Input.is_physical_key_pressed(KEY_W): input_vec.y += 1.0
    if Input.is_physical_key_pressed(KEY_S): input_vec.y -= 1.0
    input_vec = input_vec.normalized()

    var direction := (transform.basis * Vector3(input_vec.x, 0.0, -input_vec.y)).normalized()
    var target := direction * move_speed
    velocity.x = move_toward(velocity.x, target.x, acceleration * delta)
    velocity.z = move_toward(velocity.z, target.z, acceleration * delta)
    if not is_on_floor(): velocity.y -= gravity * delta
    else: velocity.y = -0.1
    move_and_slide()

    _update_interaction_target()
    _update_held_item_retraction(delta)

func has_held_item() -> bool:
    return held_item != null and is_instance_valid(held_item)

func set_payment_customer(customer: Node3D) -> void:
    payment_customer = customer

func is_payment_mode_active() -> bool:
    return payment_mode

func begin_payment_mode(target: Node3D = payment_customer) -> bool:
    if payment_mode or payment_terminal == null or not has_held_item():
        return false
    if held_item != payment_terminal or target == null:
        return false
    if not target.has_method("can_take_payment") or not target.call("can_take_payment"):
        return false
    if not payment_terminal.call("begin_payment_interaction", target):
        return false
    payment_mode = true
    Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
    _set_interaction_target(null)
    hint.text = "Click terminal buttons    ESC — cancel"
    return true

func end_payment_mode() -> void:
    if not payment_mode:
        return
    payment_mode = false
    if payment_terminal:
        payment_terminal.call("end_payment_interaction")
    Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
    hint.text = "Carrying terminal"

func _interact() -> void:
    _pick_up_interaction_target()

func _pick_up_interaction_target() -> bool:
    if interaction_target == null:
        return false
    if interaction_target.is_in_group("pickup_item") and not has_held_item():
        if interaction_target.pick_up_to(carry_anchor):
            held_item = interaction_target
            if _is_payment_terminal(held_item):
                payment_terminal = held_item
                var approval_callback := Callable(self, "_on_payment_approved")
                if not payment_terminal.is_connected("payment_approved", approval_callback):
                    payment_terminal.connect("payment_approved", approval_callback)
            _set_interaction_target(null)
            return true
    return false

func _use_held_item() -> bool:
    if interaction_target == null or not has_held_item():
        return false
    if _is_payment_customer_target(interaction_target):
        return begin_payment_mode(interaction_target as Node3D)
    if interaction_target.is_in_group("table_station"):
        if interaction_target.place_item(held_item):
            held_item = null
            _set_interaction_target(null)
            return true
    return false

func _update_interaction_target() -> void:
    ray.force_raycast_update()
    if not ray.is_colliding():
        _set_interaction_target(null)
        return
    var collider := ray.get_collider()
    if collider == null:
        _set_interaction_target(null)
        return
    var hit_distance := camera.global_position.distance_to(ray.get_collision_point())
    var target_node: Node = collider
    while target_node != null:
        if _is_payment_customer_target(target_node) and hit_distance <= payment_action_distance:
            _set_interaction_target(target_node)
            return
        if (
            target_node.is_in_group("pickup_item")
            and target_node.can_interact()
            and hit_distance <= world_pickup_distance
        ):
            _set_interaction_target(target_node)
            return
        if (
            target_node.is_in_group("table_station")
            and has_held_item()
            and target_node.can_place_item(held_item)
            and hit_distance <= held_item_action_distance
        ):
            _set_interaction_target(target_node)
            return
        target_node = target_node.get_parent()
    _set_interaction_target(null)

func _set_interaction_target(next_target: Node) -> void:
    if interaction_target == next_target:
        return
    if interaction_target and interaction_target.has_method("set_highlighted"):
        interaction_target.set_highlighted(false)
    elif interaction_target and interaction_target.has_method("set_place_highlighted"):
        interaction_target.set_place_highlighted(false)
    interaction_target = next_target
    if _is_payment_customer_target(interaction_target):
        if payment_terminal:
            payment_terminal.set_highlighted(true)
        hint.text = "LMB — Take Payment"
    elif interaction_target and interaction_target.has_method("set_highlighted"):
        interaction_target.set_highlighted(true)
        hint.text = "E — %s" % interaction_target.get_tooltip_text()
    elif interaction_target and interaction_target.has_method("set_place_highlighted"):
        interaction_target.set_place_highlighted(true)
        hint.text = "LMB — Place"
    elif has_held_item():
        hint.text = "Carrying terminal" if payment_terminal else "Carrying food"
    else:
        hint.text = "WASD — move    E — pick up    ESC — mouse"

func _is_payment_customer_target(target: Node) -> bool:
    return (
        target != null
        and target == payment_customer
        and payment_terminal != null
        and held_item == payment_terminal
        and payment_customer.has_method("can_take_payment")
        and payment_customer.call("can_take_payment")
    )

func _is_payment_terminal(item: Node) -> bool:
    return item != null and item.has_method("is_payment_terminal") and item.call("is_payment_terminal")

func _on_payment_approved(_target: Node3D, _charged_amount_cents: int) -> void:
    end_payment_mode()


func _update_held_item_retraction(delta: float) -> void:
    if not has_held_item() or carry_anchor == null or get_world_3d() == null:
        return
    var desired_position := _get_held_item_desired_position()
    var safe_position := _find_safe_carry_position(desired_position)
    # Never interpolate through a known blocker. Ordinary carry-pose changes
    # still ease, even when their target happens to be closer to the camera.
    var collision_retracted := safe_position.distance_to(desired_position) > 0.0001
    if collision_retracted:
        held_item.position = safe_position
        return
    var blend := 1.0 - exp(-held_item_restore_speed * delta)
    held_item.position = held_item.position.lerp(safe_position, blend)


func _get_held_item_desired_position() -> Vector3:
    if payment_mode and held_item == payment_terminal and payment_terminal is PaymentTerminalController:
        return (payment_terminal as PaymentTerminalController).interaction_position
    if held_item is PickupItem:
        return (held_item as PickupItem).carry_position
    return held_item.position


func _find_safe_carry_position(desired_position: Vector3) -> Vector3:
    var desired_distance := desired_position.length()
    if desired_distance <= 0.001 or not (held_item is PickupItem):
        return desired_position
    var proxy_shape := (held_item as PickupItem).get_held_collision_shape()
    if proxy_shape == null:
        return desired_position
    var direction := desired_position / desired_distance
    var local_proxy_offset := (held_item as PickupItem).get_held_collision_offset()
    var item_basis := carry_anchor.global_transform.basis * held_item.transform.basis
    var proxy_basis := item_basis * (held_item as PickupItem).get_held_collision_rotation()
    _held_item_query.shape = proxy_shape
    _held_item_query.transform = Transform3D(
        proxy_basis,
        carry_anchor.global_position + item_basis * local_proxy_offset
    )
    _held_item_query.motion = carry_anchor.global_transform.basis * desired_position
    _held_item_query.margin = held_item_wall_padding
    _held_item_query.collision_mask = held_item_obstacle_mask
    _held_item_query.collide_with_bodies = true
    _held_item_query.collide_with_areas = false
    _held_item_query.exclude = [get_rid()]
    var cast_result := get_world_3d().direct_space_state.cast_motion(_held_item_query)
    var safe_fraction := cast_result[0] if cast_result.size() >= 2 else 1.0
    if safe_fraction >= 0.9999:
        return desired_position
    # cast_motion returns the first safe fraction for the entire oriented proxy.
    # Collision safety wins over preserving the nominal carry distance.
    var safe_distance := maxf(desired_distance * safe_fraction, 0.0)
    return direction * safe_distance
