class_name CustomerController
extends CharacterBody3D

signal seating_state_changed(state_name: StringName)

enum SeatingState {
    IDLE,
    WALK_TO_CHAIR,
    ALIGN_TO_CHAIR,
    SIT_DOWN,
    SEATED,
    CALL_WAITER,
    CALL_WAITER_MENU,
}

@export var walk_speed := 1.65
@export var model_yaw_offset_degrees := 180.0
@export var final_alignment_duration := 0.32

@onready var visual: Node3D = $Visual
@onready var model_root: Node3D = $Visual/CustomerModel
@onready var emotion_anchor: Node3D = $EmotionAnchor
@onready var emotion_label: Label3D = $EmotionAnchor/EmotionLabel

var animation_player: AnimationPlayer
var skeleton: Skeleton3D
var head_look_modifier
var head_look_target: Node3D
var table_station: TableStation
var entry_point: Marker3D
var exit_point: Marker3D
var seating_running := false
var seating_state := SeatingState.IDLE
var call_waiter_cycles := 0

var menu_node: Node3D
var spoon_node: Node3D
var phone_node: Node3D
var brow_l: Node3D
var brow_r: Node3D
var mouth: Node3D
var face_base := {}

const PHONE_SCENE := preload("res://assets/props/phone.glb")
const HEAD_LOOK_MODIFIER_SCRIPT := preload("res://scripts/head_look_modifier.gd")

func _ready() -> void:
    animation_player = _find_animation_player(model_root)
    skeleton = _find_skeleton(model_root)
    _setup_head_look()
    menu_node = model_root.find_child("MenuBook", true, false) as Node3D
    spoon_node = model_root.find_child("Spoon", true, false) as Node3D
    brow_l = model_root.find_child("Eyebrow_L", true, false) as Node3D
    brow_r = model_root.find_child("Eyebrow_R", true, false) as Node3D
    mouth = model_root.find_child("Mouth", true, false) as Node3D
    _capture_face()
    _hide_props()
    _setup_phone()
    ComicStyle.apply(model_root, 0.010)
    emotion_label.modulate.a = 0.0
    emotion_label.visible = false

func configure(station: TableStation, entry: Marker3D, exit: Marker3D) -> void:
    table_station = station
    entry_point = entry
    exit_point = exit
    global_position = entry_point.global_position

func start_loop() -> void:
    start_seating_sequence()

func start_seating_sequence() -> void:
    if seating_running or table_station == null or entry_point == null:
        return
    seating_running = true
    call_waiter_cycles = 0
    call_deferred("_run_seating_sequence")

func _run_seating_sequence() -> void:
    visible = true
    global_position = entry_point.global_position
    set_face_state("neutral")

    _set_seating_state(SeatingState.WALK_TO_CHAIR)
    await _walk_to(table_station.approach_point.global_position)

    _set_seating_state(SeatingState.ALIGN_TO_CHAIR)
    await _align_to_seat()

    _set_seating_state(SeatingState.SIT_DOWN)
    await _play_once("SitDown")
    global_transform = table_station.seat_point.global_transform

    _set_seating_state(SeatingState.SEATED)
    await get_tree().physics_frame

    _set_seating_state(SeatingState.CALL_WAITER)
    while seating_running:
        global_transform = table_station.seat_point.global_transform
        call_waiter_cycles += 1
        await _play_for_duration("CallWaiter")
        global_transform = table_station.seat_point.global_transform

func _set_seating_state(next_state: SeatingState) -> void:
    seating_state = next_state
    set_head_look_enabled(
        next_state == SeatingState.CALL_WAITER
        or next_state == SeatingState.CALL_WAITER_MENU
    )
    seating_state_changed.emit(SeatingState.keys()[next_state])

func set_head_look_target(target: Node3D) -> void:
    head_look_target = target
    if head_look_modifier:
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
    _face_toward(table_station.look_point.global_position)
    var original_mask := collision_mask
    collision_mask = 0
    var tween := create_tween()
    tween.tween_property(self, "global_position", table_station.seat_point.global_position, final_alignment_duration) \
        .set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
    await tween.finished
    collision_mask = original_mask
    global_transform = table_station.seat_point.global_transform
    _face_toward(table_station.look_point.global_position)

func _walk_to(target: Vector3) -> void:
    _play_loop("Walk")
    while global_position.distance_to(target) > 0.06:
        var delta := get_physics_process_delta_time()
        var direction := target - global_position
        direction.y = 0.0
        if direction.length() < 0.001: break
        direction = direction.normalized()
        _face_direction(direction)
        velocity = direction * walk_speed
        move_and_slide()
        await get_tree().physics_frame
    velocity = Vector3.ZERO
    if animation_player: animation_player.stop()

func _face_direction(direction: Vector3) -> void:
    var yaw := atan2(direction.x, direction.z) + deg_to_rad(model_yaw_offset_degrees)
    visual.rotation.y = yaw

func _face_toward(target: Vector3) -> void:
    var d := target - global_position
    d.y = 0.0
    if d.length() > 0.001: _face_direction(d.normalized())

func _play_loop(name: StringName) -> void:
    if animation_player == null or not animation_player.has_animation(name): return
    var anim := animation_player.get_animation(name)
    if anim: anim.loop_mode = Animation.LOOP_LINEAR
    animation_player.play(name, 0.16)

func _play_once(name: StringName) -> void:
    if animation_player == null or not animation_player.has_animation(name):
        await get_tree().create_timer(0.5).timeout
        return
    var anim := animation_player.get_animation(name)
    if anim: anim.loop_mode = Animation.LOOP_NONE
    animation_player.play(name, 0.12)
    await animation_player.animation_finished

func _play_for_duration(name: StringName) -> void:
    if animation_player == null or not animation_player.has_animation(name):
        return
    var animation := animation_player.get_animation(name)
    if animation == null:
        return
    animation.loop_mode = Animation.LOOP_NONE
    animation_player.play(name, 0.12)
    await get_tree().create_timer(animation.length).timeout

func _find_animation_player(node: Node) -> AnimationPlayer:
    if node is AnimationPlayer: return node
    for child in node.get_children():
        var found := _find_animation_player(child)
        if found: return found
    return null

func _find_skeleton(node: Node) -> Skeleton3D:
    if node is Skeleton3D: return node
    for child in node.get_children():
        var found := _find_skeleton(child)
        if found: return found
    return null

func _hide_props() -> void:
    _set_prop(menu_node, false)
    _set_prop(spoon_node, false)

func _set_prop(node: Node3D, value: bool) -> void:
    if node: node.visible = value

func _setup_phone() -> void:
    if skeleton == null: return
    if skeleton.find_bone("Phone_Hold") < 0: return
    var attachment := BoneAttachment3D.new()
    attachment.name = "PhoneAttachment"
    attachment.bone_name = "Phone_Hold"
    skeleton.add_child(attachment)
    phone_node = PHONE_SCENE.instantiate() as Node3D
    attachment.add_child(phone_node)
    phone_node.scale = Vector3.ONE * 0.72
    phone_node.visible = false
    ComicStyle.apply(phone_node, 0.008)

func _phone_visibility_sequence() -> void:
    if phone_node == null: return
    phone_node.visible = false
    _show_phone_after_delay()

func _show_phone_after_delay() -> void:
    await get_tree().create_timer(0.30).timeout
    if phone_node: phone_node.visible = true
    await get_tree().create_timer(1.45).timeout
    if phone_node: phone_node.visible = false

func _capture_face() -> void:
    for pair in [["brow_l", brow_l], ["brow_r", brow_r], ["mouth", mouth]]:
        var n: Node3D = pair[1]
        if n:
            face_base[pair[0]] = {"position": n.position, "rotation": n.rotation, "scale": n.scale}

func _restore_face_node(key: String, node: Node3D) -> void:
    if node == null or not face_base.has(key): return
    node.position = face_base[key]["position"]
    node.rotation = face_base[key]["rotation"]
    node.scale = face_base[key]["scale"]

func set_face_state(state: String) -> void:
    _restore_face_node("brow_l", brow_l)
    _restore_face_node("brow_r", brow_r)
    _restore_face_node("mouth", mouth)
    match state:
        "sad":
            if brow_l: brow_l.rotation.z += 0.17
            if brow_r: brow_r.rotation.z -= 0.17
            if mouth: mouth.position.y += 0.012
        "happy":
            if brow_l: brow_l.rotation.z -= 0.06
            if brow_r: brow_r.rotation.z += 0.06
            if mouth: mouth.scale.x *= 1.20
        "angry":
            if brow_l: brow_l.rotation.z -= 0.18
            if brow_r: brow_r.rotation.z += 0.18
            if brow_l: brow_l.position.y -= 0.014
            if brow_r: brow_r.position.y -= 0.014
        _:
            pass

func show_emotion(symbol: String) -> void:
    emotion_label.text = symbol
    emotion_label.visible = true
    emotion_label.modulate.a = 0.0
    emotion_anchor.position.y = 0.0
    var tween := create_tween()
    tween.set_parallel(true)
    tween.tween_property(emotion_label, "modulate:a", 1.0, 0.15)
    tween.tween_property(emotion_anchor, "position:y", 0.18, 0.30)
    await get_tree().create_timer(0.85).timeout
    var out := create_tween()
    out.set_parallel(true)
    out.tween_property(emotion_label, "modulate:a", 0.0, 0.35)
    out.tween_property(emotion_anchor, "position:y", 0.48, 0.35)
    await out.finished
    emotion_label.visible = false
