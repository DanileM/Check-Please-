class_name CustomerController
extends CharacterBody3D

signal seating_state_changed(state_name: StringName)

enum SeatingState {
    IDLE,
    WALK_TO_CHAIR,
    ALIGN_TO_CHAIR,
    SIT_DOWN,
    SEATED,
    TAKE_MENU,
    STUDY_MENU,
    CALL_WAITER_MENU_NORMAL,
    CALL_WAITER_MENU_IMPATIENT,
    TAKE_SPOON,
    EAT,
    PUT_AWAY_SPOON,
    CALL_WAITER_EMPTY,
    REQUEST_PAYMENT,
    WAIT_FOR_PAYMENT,
    PAYMENT_ACCEPTED,
    LEAVE_REVIEW,
    PUT_AWAY_MENU,
    LEAVE_BAD_REVIEW,
    STAND_UP,
    LEAVE,
    COMPLETE,
    # Kept for callers/tests that use the pre-escalation calling states.
    CALL_WAITER,
    CALL_WAITER_MENU,
}

@export_group("Movement")
@export var walk_speed := 1.65
@export var model_yaw_offset_degrees := 180.0
@export var final_alignment_duration := 0.32
@export var seat_transition_duration := 0.26
@export var seat_exit_transition_duration := 0.28

@export_group("Customer Escalation")
@export var menu_read_duration := 5.0
@export var normal_call_duration := 5.0
@export var impatient_call_duration := 5.0
@export var normal_call_animation_speed := 1.0
@export var impatient_call_animation_speed := 1.6
@export_range(0.0, 1.0, 0.01) var menu_show_fraction := 0.28
@export_range(0.0, 1.0, 0.01) var phone_show_fraction := 0.24
@export_range(1.0, 5.0, 0.5) var final_review_score := 1.0

@export_group("Food Service")
@export var eat_duration := 5.0
@export_range(0.0, 1.0, 0.01) var spoon_show_fraction := 0.30
@export var empty_plate_call_animation_speed := 1.0

@export_group("Payment")
@export var burger_price_cents := 200

@onready var visual: Node3D = $Visual
@onready var standing_collision_shape: CollisionShape3D = $CollisionShape3D
@onready var payment_interaction_area: Area3D = $PaymentInteractionArea
@onready var model_root: Node3D = $Visual/CustomerModel
@onready var emotion_anchor: Node3D = $EmotionAnchor
@onready var emotion_label: Label3D = $EmotionAnchor/EmotionLabel
@onready var status_icon = $StatusIconAnchor/CustomerStatusIcon
@onready var order_bubble = $StatusIconAnchor/OrderBubble
@onready var hand_props: Node3D = $HandProps

var animation_player: AnimationPlayer
var skeleton: Skeleton3D
var head_look_modifier
var head_look_target: Node3D
var table_station: TableStation
var entry_point: Marker3D
var exit_point: Marker3D
var seating_running := false
var seating_transition_active := false
var seating_state := SeatingState.IDLE
var call_waiter_cycles := 0

var menu_node: Node3D
var phone_node: Node3D
var spoon_node: Node3D
var payment_card_node: Node3D
var brow_l: Node3D
var brow_r: Node3D
var mouth: Node3D
var face_base := {}
var _waiter_interaction_received := false
var _food_delivery_received := false
var _served_food: Node3D
var locked_review_face_state := ""
var order_line_items: Array[Dictionary] = []

const HEAD_LOOK_MODIFIER_SCRIPT := preload("res://scripts/head_look_modifier.gd")
const MENU_POSE_HOLD: StringName = &"hold"
const MENU_POSE_READ: StringName = &"read"
const MENU_POSE_CALL: StringName = &"call"
const MENU_POSE_PUT_AWAY: StringName = &"put_away"


func _ready() -> void:
    animation_player = _find_animation_player(model_root)
    skeleton = _find_skeleton(model_root)
    _setup_head_look()
    _setup_hand_props()
    brow_l = model_root.find_child("Eyebrow_L", true, false) as Node3D
    brow_r = model_root.find_child("Eyebrow_R", true, false) as Node3D
    mouth = model_root.find_child("Mouth", true, false) as Node3D
    _capture_face()
    _hide_props()
    ComicStyle.apply(model_root, 0.010, 0.08)
    emotion_label.modulate.a = 0.0
    emotion_label.visible = false
    _set_standing_collision_enabled(true)
    _set_payment_interaction_target_enabled(false)


func configure(station: TableStation, entry: Marker3D, exit: Marker3D) -> void:
    table_station = station
    entry_point = entry
    exit_point = exit
    global_position = entry_point.global_position


func start_loop() -> void:
    start_seating_sequence()


func start_seating_sequence() -> void:
    if seating_running or table_station == null or entry_point == null or exit_point == null:
        return
    seating_running = true
    seating_transition_active = false
    _set_standing_collision_enabled(true)
    call_waiter_cycles = 0
    _waiter_interaction_received = false
    _food_delivery_received = false
    _served_food = null
    locked_review_face_state = ""
    order_line_items = [{
        "item_id": &"burger",
        "unit_price_cents": burger_price_cents,
        "quantity": 1,
    }]
    call_deferred("_run_seating_sequence")


func on_waiter_interaction() -> void:
    # A future waiter/service system can call this to stop the automatic
    # escalation. The current sequence deliberately has no input hookup.
    _waiter_interaction_received = true


func can_accept_food() -> bool:
    return seating_running and (
        seating_state == SeatingState.CALL_WAITER_MENU_NORMAL
        or seating_state == SeatingState.CALL_WAITER_MENU_IMPATIENT
    )


func accept_delivered_food(food: Node3D) -> bool:
    if not can_accept_food() or food == null:
        return false
    _served_food = food
    _food_delivery_received = true
    _waiter_interaction_received = true
    return true


func get_amount_due_cents() -> int:
    var total := 0
    for item in order_line_items:
        total += int(item.get("unit_price_cents", 0)) * int(item.get("quantity", 0))
    return max(total, 0)


func can_take_payment() -> bool:
    return seating_running and seating_state == SeatingState.WAIT_FOR_PAYMENT


func complete_payment(charged_amount_cents: int) -> bool:
    if not can_take_payment() or charged_amount_cents != get_amount_due_cents():
        return false
    _set_seating_state(SeatingState.PAYMENT_ACCEPTED)
    return true


func seating_state_name() -> StringName:
    return SeatingState.keys()[seating_state]


func get_locked_review_face_state() -> String:
    return locked_review_face_state


func _run_seating_sequence() -> void:
    visible = true
    global_position = entry_point.global_position
    set_face_state("neutral")

    _set_seating_state(SeatingState.WALK_TO_CHAIR)
    await _walk_to(table_station.approach_point.global_position)
    if not seating_running:
        return

    _set_seating_state(SeatingState.ALIGN_TO_CHAIR)
    await _align_to_seat()

    _set_seating_state(SeatingState.SIT_DOWN)
    await _play_once(&"SitDown")
    _lock_to_seat_point()

    _set_seating_state(SeatingState.SEATED)
    await get_tree().physics_frame

    _set_seating_state(SeatingState.TAKE_MENU)
    _set_menu_visible_after_animation_fraction(true, MENU_POSE_HOLD, &"TakeMenu", menu_show_fraction)
    await _play_once(&"TakeMenu")
    _set_menu_visible(true, MENU_POSE_HOLD)

    _set_seating_state(SeatingState.STUDY_MENU)
    _set_menu_visible(true, MENU_POSE_READ)
    _play_loop(&"ReadMenu", normal_call_animation_speed)
    if not await _wait_for_duration(menu_read_duration):
        _handoff_to_waiter()
        return
    _stop_animation()

    _set_seating_state(SeatingState.CALL_WAITER_MENU_NORMAL)
    _set_menu_visible(true, MENU_POSE_CALL)
    _show_order_bubble(false)
    call_waiter_cycles += 1
    _play_loop(&"CallWaiterMenu", normal_call_animation_speed)
    if not await _wait_for_duration(normal_call_duration):
        if _food_delivery_received:
            await _run_food_delivery_sequence()
            return
        _handoff_to_waiter()
        return
    _stop_animation()

    _set_seating_state(SeatingState.CALL_WAITER_MENU_IMPATIENT)
    _set_menu_visible(true, MENU_POSE_CALL)
    set_face_state("angry")
    _show_order_bubble(true)
    call_waiter_cycles += 1
    _play_loop(&"CallWaiterMenu", impatient_call_animation_speed)
    if not await _wait_for_duration(impatient_call_duration):
        if _food_delivery_received:
            await _run_food_delivery_sequence()
            return
        _handoff_to_waiter()
        return
    _stop_animation()
    _hide_order_bubble()

    _set_seating_state(SeatingState.PUT_AWAY_MENU)
    _set_menu_visible(true, MENU_POSE_PUT_AWAY)
    set_face_state("neutral")
    await _play_once(&"PutAwayMenu")
    _set_menu_visible(false, MENU_POSE_PUT_AWAY)

    await _run_review_and_departure(SeatingState.LEAVE_BAD_REVIEW)


func _handoff_to_waiter() -> void:
    _stop_animation()
    _hide_status()
    _hide_order_bubble()
    set_face_state("neutral")
    _set_seating_state(SeatingState.SEATED)


func _run_food_delivery_sequence() -> void:
    _food_delivery_received = false
    _waiter_interaction_received = false
    _stop_animation()
    _hide_order_bubble()
    set_face_state("neutral")

    _set_seating_state(SeatingState.PUT_AWAY_MENU)
    _set_menu_visible(true, MENU_POSE_PUT_AWAY)
    await _play_once(&"PutAwayMenu")
    _set_menu_visible(false, MENU_POSE_PUT_AWAY)

    _set_seating_state(SeatingState.TAKE_SPOON)
    _set_spoon_visible_after_animation_fraction(&"TakeSpoon", spoon_show_fraction)
    await _play_once(&"TakeSpoon")
    _set_spoon_visible(true)

    _set_seating_state(SeatingState.EAT)
    _play_loop(&"Eat")
    await _wait_for_duration(eat_duration)
    _stop_animation()
    if _served_food and _served_food.has_method("set_burger_visible"):
        _served_food.call("set_burger_visible", false)
    if table_station:
        table_station.enable_empty_plate_pickup()

    _set_seating_state(SeatingState.PUT_AWAY_SPOON)
    await _play_once(&"PutAwaySpoon")
    _set_spoon_visible(false)

    await _run_payment_request_sequence()


func _run_payment_request_sequence() -> void:
    _set_seating_state(SeatingState.REQUEST_PAYMENT)
    _set_payment_card_visible(true)
    _show_payment_bubble()
    _play_loop(&"CallWaiter", empty_plate_call_animation_speed)

    _set_seating_state(SeatingState.WAIT_FOR_PAYMENT)
    while seating_running and seating_state == SeatingState.WAIT_FOR_PAYMENT:
        await get_tree().process_frame
    if not seating_running or seating_state != SeatingState.PAYMENT_ACCEPTED:
        return

    _stop_animation()
    _set_payment_card_visible(false)
    _hide_order_bubble()
    await _run_review_and_departure(SeatingState.LEAVE_REVIEW)


func _run_review_and_departure(review_state: SeatingState) -> void:
    _set_seating_state(review_state)
    _set_phone_review_after_animation_fraction(&"LeaveReview", phone_show_fraction)
    await _play_once(&"LeaveReview")
    _set_phone_review_visible(false)

    _set_seating_state(SeatingState.STAND_UP)
    await _play_once(&"StandUp")
    _lock_to_seat_point()
    await _move_out_of_seat()
    _set_standing_collision_enabled(true)
    await get_tree().physics_frame

    _set_seating_state(SeatingState.LEAVE)
    await _walk_to(exit_point.global_position)
    visible = false
    seating_running = false
    _set_seating_state(SeatingState.COMPLETE)


func _set_seating_state(next_state: SeatingState) -> void:
    seating_state = next_state
    _set_payment_interaction_target_enabled(next_state == SeatingState.WAIT_FOR_PAYMENT)
    var state_target: Node3D = head_look_target
    var should_track := (
        next_state == SeatingState.CALL_WAITER
        or next_state == SeatingState.CALL_WAITER_MENU
        or next_state == SeatingState.CALL_WAITER_MENU_NORMAL
        or next_state == SeatingState.CALL_WAITER_MENU_IMPATIENT
        or next_state == SeatingState.CALL_WAITER_EMPTY
        or next_state == SeatingState.REQUEST_PAYMENT
        or next_state == SeatingState.WAIT_FOR_PAYMENT
    )
    if next_state == SeatingState.STUDY_MENU:
        state_target = hand_props.get_menu_read_target()
        should_track = state_target != null
    if head_look_modifier:
        head_look_modifier.set_head_look_target(state_target)
    set_head_look_enabled(should_track)
    seating_state_changed.emit(SeatingState.keys()[next_state])


func _set_payment_interaction_target_enabled(enabled: bool) -> void:
    if payment_interaction_area == null:
        return
    payment_interaction_area.collision_layer = 1 if enabled else 0
    payment_interaction_area.monitoring = enabled
    payment_interaction_area.monitorable = enabled


func set_head_look_target(target: Node3D) -> void:
    head_look_target = target
    if head_look_modifier and seating_state != SeatingState.STUDY_MENU:
        head_look_modifier.set_head_look_target(target)


func set_head_look_enabled(enabled: bool) -> void:
    if head_look_modifier:
        head_look_modifier.set_head_look_enabled(enabled)


func get_head_look_modifier():
    return head_look_modifier


func _setup_head_look() -> void:
    if skeleton == null:
        push_warning("Customer head look disabled: Skeleton3D was not found")
        return
    head_look_modifier = HEAD_LOOK_MODIFIER_SCRIPT.new()
    head_look_modifier.name = "HeadLookModifier"
    skeleton.add_child(head_look_modifier)
    head_look_modifier.configure(&"Head_2")
    head_look_modifier.set_head_look_target(head_look_target)
    head_look_modifier.set_head_look_enabled(false)


func _align_to_seat() -> void:
    velocity = Vector3.ZERO
    await _align_visual_to_seat()
    _set_standing_collision_enabled(false)
    await get_tree().physics_frame
    seating_transition_active = true
    var tween := create_tween()
    tween.tween_property(self, "global_position", table_station.seat_point.global_position, seat_transition_duration) \
        .set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
    await tween.finished
    _lock_to_seat_point()
    _face_toward(table_station.look_point.global_position)
    seating_transition_active = false


func _align_visual_to_seat() -> void:
    var direction := table_station.look_point.global_position - global_position
    direction.y = 0.0
    if direction.length_squared() < 0.000001:
        return
    var target_yaw := atan2(direction.x, direction.z) + deg_to_rad(model_yaw_offset_degrees)
    var tween := create_tween()
    tween.tween_property(visual, "rotation:y", target_yaw, final_alignment_duration) \
        .set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
    await tween.finished


func _move_out_of_seat() -> void:
    var exit_anchor := table_station.exit_point if table_station.exit_point else table_station.approach_point
    seating_transition_active = true
    _lock_to_seat_point()
    var tween := create_tween()
    tween.tween_property(self, "global_position", exit_anchor.global_position, seat_exit_transition_duration) \
        .set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
    await tween.finished
    global_position = exit_anchor.global_position
    velocity = Vector3.ZERO
    seating_transition_active = false


func _lock_to_seat_point() -> void:
    if table_station:
        global_position = table_station.seat_point.global_position
    velocity = Vector3.ZERO


func _set_standing_collision_enabled(enabled: bool) -> void:
    if standing_collision_shape:
        standing_collision_shape.set_deferred("disabled", not enabled)


func _physics_process(_delta: float) -> void:
    var is_seated_phase := seating_state >= SeatingState.SEATED and seating_state <= SeatingState.STAND_UP
    if is_seated_phase and not seating_transition_active:
        _lock_to_seat_point()


func _walk_to(target: Vector3, ignore_collision := false) -> void:
    _play_loop(&"Walk")
    var original_mask := collision_mask
    if ignore_collision:
        collision_mask = 0
    while global_position.distance_to(target) > 0.06:
        var delta := get_physics_process_delta_time()
        var direction := target - global_position
        direction.y = 0.0
        if direction.length() < 0.001:
            break
        direction = direction.normalized()
        _face_direction(direction)
        velocity = direction * walk_speed
        move_and_slide()
        if delta <= 0.0:
            break
        await get_tree().physics_frame
    velocity = Vector3.ZERO
    collision_mask = original_mask
    _stop_animation()


func _face_direction(direction: Vector3) -> void:
    var yaw := atan2(direction.x, direction.z) + deg_to_rad(model_yaw_offset_degrees)
    visual.rotation.y = yaw


func _face_toward(target: Vector3) -> void:
    var direction := target - global_position
    direction.y = 0.0
    if direction.length() > 0.001:
        _face_direction(direction.normalized())


func _play_loop(name: StringName, speed := 1.0) -> void:
    if animation_player == null or not animation_player.has_animation(name):
        return
    var animation := animation_player.get_animation(name)
    if animation:
        animation.loop_mode = Animation.LOOP_LINEAR
    animation_player.speed_scale = speed
    animation_player.play(name, 0.16)


func _play_once(name: StringName) -> void:
    if animation_player == null or not animation_player.has_animation(name):
        await get_tree().create_timer(0.5).timeout
        return
    var animation := animation_player.get_animation(name)
    if animation:
        animation.loop_mode = Animation.LOOP_NONE
    animation_player.speed_scale = 1.0
    animation_player.play(name, 0.12)
    await animation_player.animation_finished


func _stop_animation() -> void:
    if animation_player:
        animation_player.stop()
        animation_player.speed_scale = 1.0


func _wait_for_duration(duration: float, update_status_fill := false) -> bool:
    var elapsed := 0.0
    var safe_duration := maxf(duration, 0.0)
    while elapsed < safe_duration:
        await get_tree().process_frame
        elapsed += get_process_delta_time()
        if update_status_fill:
            status_icon.set_fill_progress(elapsed / maxf(safe_duration, 0.001))
        if _waiter_interaction_received:
            return false
    if update_status_fill:
        status_icon.set_fill_progress(1.0)
    return true


func _animation_length(name: StringName) -> float:
    if animation_player == null:
        return 0.0
    var animation := animation_player.get_animation(name)
    return animation.length if animation else 0.0


func _set_menu_visible_after_animation_fraction(
    visible_value: bool,
    pose: StringName,
    animation_name: StringName,
    fraction: float
) -> void:
    await get_tree().create_timer(_animation_length(animation_name) * clampf(fraction, 0.0, 1.0)).timeout
    _set_menu_visible(visible_value, pose)


func _set_phone_review_after_animation_fraction(animation_name: StringName, fraction: float) -> void:
    _set_phone_review_visible(false)
    await get_tree().create_timer(_animation_length(animation_name) * clampf(fraction, 0.0, 1.0)).timeout
    _set_phone_review_visible(true)
    _submit_final_review()


func _set_spoon_visible_after_animation_fraction(animation_name: StringName, fraction: float) -> void:
    _set_spoon_visible(false)
    await get_tree().create_timer(_animation_length(animation_name) * clampf(fraction, 0.0, 1.0)).timeout
    _set_spoon_visible(true)


func _find_animation_player(node: Node) -> AnimationPlayer:
    if node is AnimationPlayer:
        return node
    for child in node.get_children():
        var found := _find_animation_player(child)
        if found:
            return found
    return null


func _find_skeleton(node: Node) -> Skeleton3D:
    if node is Skeleton3D:
        return node
    for child in node.get_children():
        var found := _find_skeleton(child)
        if found:
            return found
    return null


func _hide_props() -> void:
    _set_menu_visible(false, MENU_POSE_HOLD)
    _set_phone_review_visible(false)
    _set_spoon_visible(false)
    _set_payment_card_visible(false)
    _hide_status()
    _hide_order_bubble()


func _set_prop(node: Node3D, value: bool) -> void:
    if node:
        node.visible = value


func _setup_hand_props() -> void:
    hand_props.setup(skeleton)
    menu_node = hand_props.menu_node
    phone_node = hand_props.phone_node
    spoon_node = hand_props.spoon_node
    payment_card_node = hand_props.payment_card_node
    if menu_node:
        ComicStyle.apply(menu_node, 0.008, 0.08)
    if phone_node:
        ComicStyle.apply(phone_node, 0.008, 0.08)
    if spoon_node:
        ComicStyle.apply(spoon_node, 0.008, 0.08)


func _set_phone_review_visible(value: bool) -> void:
    hand_props.set_phone_review_visible(value)


func _set_spoon_visible(value: bool) -> void:
    hand_props.set_spoon_visible(value)


func _set_payment_card_visible(value: bool) -> void:
    hand_props.set_payment_card_visible(value)


func _set_menu_visible(value: bool, pose: StringName) -> void:
    hand_props.set_menu_visible(value, pose)


func _show_status(symbol: String, fill_progress: float, shaking: bool) -> void:
    if status_icon == null:
        return
    status_icon.show_icon(symbol)
    status_icon.set_fill_progress(fill_progress)
    status_icon.set_shaking(shaking)


func _hide_status() -> void:
    if status_icon:
        status_icon.hide_icon()


func _show_order_bubble(shaking: bool) -> void:
    if order_bubble == null:
        return
    order_bubble.show_order(PackedStringArray(["burger"]))
    order_bubble.set_shaking(shaking)


func _show_payment_bubble() -> void:
    if order_bubble == null:
        return
    order_bubble.show_order(PackedStringArray(["payment"]))
    order_bubble.set_shaking(false)


func _hide_order_bubble() -> void:
    if order_bubble:
        order_bubble.hide_order()


func _submit_final_review() -> void:
    locked_review_face_state = _face_state_for_review_score(final_review_score)
    set_face_state(locked_review_face_state)
    _show_status(_review_status_symbol(), 1.0, false)


func _face_state_for_review_score(score: float) -> String:
    if score < 2.0:
        return "sad"
    if score <= 3.0:
        return "neutral"
    return "happy"


func _review_status_symbol() -> String:
    return "★ %d/5" % clampi(roundi(final_review_score), 1, 5)


func _capture_face() -> void:
    for pair in [["brow_l", brow_l], ["brow_r", brow_r], ["mouth", mouth]]:
        var node: Node3D = pair[1]
        if node:
            face_base[pair[0]] = {"position": node.position, "rotation": node.rotation, "scale": node.scale}


func _restore_face_node(key: String, node: Node3D) -> void:
    if node == null or not face_base.has(key):
        return
    node.position = face_base[key]["position"]
    node.rotation = face_base[key]["rotation"]
    node.scale = face_base[key]["scale"]


func set_face_state(state: String) -> void:
    _restore_face_node("brow_l", brow_l)
    _restore_face_node("brow_r", brow_r)
    _restore_face_node("mouth", mouth)
    match state:
        "sad":
            if brow_l:
                brow_l.rotation.z += 0.17
            if brow_r:
                brow_r.rotation.z -= 0.17
            if mouth:
                mouth.position.y += 0.012
        "happy":
            if brow_l:
                brow_l.rotation.z -= 0.06
            if brow_r:
                brow_r.rotation.z += 0.06
            if mouth:
                mouth.scale.x *= 1.20
        "angry":
            if brow_l:
                brow_l.rotation.z -= 0.18
            if brow_r:
                brow_r.rotation.z += 0.18
            if brow_l:
                brow_l.position.y -= 0.014
            if brow_r:
                brow_r.position.y -= 0.014
        _:
            pass


func show_emotion(symbol: String) -> void:
    _show_status(symbol, 1.0, false)
    await get_tree().create_timer(0.85).timeout
    _hide_status()
