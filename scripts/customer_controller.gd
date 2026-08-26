class_name CustomerController
extends CharacterBody3D

@export var walk_speed := 1.65
@export var model_yaw_offset_degrees := 180.0

@onready var visual: Node3D = $Visual
@onready var model_root: Node3D = $Visual/CustomerModel
@onready var emotion_anchor: Node3D = $EmotionAnchor
@onready var emotion_label: Label3D = $EmotionAnchor/EmotionLabel

var animation_player: AnimationPlayer
var skeleton: Skeleton3D
var table_station: TableStation
var entry_point: Marker3D
var exit_point: Marker3D
var running := false

var menu_node: Node3D
var spoon_node: Node3D
var phone_node: Node3D
var brow_l: Node3D
var brow_r: Node3D
var mouth: Node3D
var face_base := {}

const PHONE_SCENE := preload("res://assets/props/phone.glb")

func _ready() -> void:
    animation_player = _find_animation_player(model_root)
    skeleton = _find_skeleton(model_root)
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
    if running: return
    running = true
    _customer_loop()

func _customer_loop() -> void:
    while running:
        visible = true
        global_position = entry_point.global_position
        set_face_state("neutral")
        await _walk_to(table_station.approach_point.global_position)
        _face_toward(table_station.global_position)
        global_position = table_station.seat_point.global_position
        await _play_once("SitDown")

        set_face_state("neutral")
        _set_prop(menu_node, true)
        await _play_once("TakeMenu")

        set_face_state("angry")
        await _play_once("ReadMenu")

        set_face_state("sad")
        show_emotion("!")
        await _play_once("CallWaiterMenu")
        await _play_once("PutAwayMenu")
        _set_prop(menu_node, false)

        set_face_state("neutral")
        _set_prop(spoon_node, true)
        await _play_once("TakeSpoon")
        set_face_state("happy")
        show_emotion("+")
        await _play_once("Eat")
        await _play_once("PutAwaySpoon")
        _set_prop(spoon_node, false)

        set_face_state("sad")
        show_emotion("?")
        await _play_once("CallWaiter")

        set_face_state("happy")
        _phone_visibility_sequence()
        await _play_once("LeaveReview")
        show_emotion("★")

        set_face_state("neutral")
        await _play_once("StandUp")
        await _walk_to(exit_point.global_position)
        visible = false
        await get_tree().create_timer(1.2).timeout

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
