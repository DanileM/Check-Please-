class_name CustomerHandProps
extends Node3D

const MENU_POSE_HOLD: StringName = &"hold"
const MENU_POSE_READ: StringName = &"read"
const MENU_POSE_CALL: StringName = &"call"
const MENU_POSE_PUT_AWAY: StringName = &"put_away"

@export_group("Payment Card Presentation")
@export var payment_card_bone: StringName = &"Arm_R_2"
@export var payment_card_position := Vector3(-0.18, -0.42, 0.55)
@export var payment_card_rotation_degrees := Vector3(0.0, -83.0, 0.0)
@export var payment_card_scale := Vector3(2.8, 2.8, 2.8)

@export_group("Menu Presentation")
@export var menu_scale := Vector3(1.25, 1.25, 1.25)
@export var menu_hold_position := Vector3(0.0, 0.025, 0.020)
@export var menu_hold_rotation_degrees := Vector3(-16.0, 8.0, 6.0)
@export var menu_read_position := Vector3(0.0, 0.065, 0.035)
@export var menu_read_rotation_degrees := Vector3(-22.0, 8.0, 8.0)
@export var menu_call_position := Vector3(0.0, 0.045, 0.025)
@export var menu_call_rotation_degrees := Vector3(-18.0, 10.0, 7.0)

@export_group("Phone Presentation")
@export var phone_scale := Vector3(1.55, 1.55, 1.55)
@export var phone_review_position := Vector3(0.18, 0.155, 0.34)
@export var phone_review_rotation_degrees := Vector3(-8.0, 0.0, 12.0)

@export_group("Spoon Presentation")
@export var spoon_scale := Vector3(1.0, 1.0, 1.0)
@export var spoon_position := Vector3.ZERO
@export var spoon_rotation_degrees := Vector3.ZERO

var menu_attachment: BoneAttachment3D
var phone_attachment: BoneAttachment3D
var spoon_attachment: BoneAttachment3D
var payment_card_attachment: BoneAttachment3D
var menu_node: Node3D
var phone_node: Node3D
var spoon_node: Node3D
var payment_card_node: Node3D
var _menu_read_target: Marker3D

const MENU_SCENE := preload("res://assets/props/menu.glb")
const PHONE_SCENE := preload("res://assets/props/phone.glb")
const SPOON_SCENE := preload("res://assets/props/spoon.glb")
const PAYMENT_CARD_SCENE := preload("res://assets/props/credit_card.glb")


func setup(skeleton: Skeleton3D) -> void:
    if skeleton == null or menu_node != null or phone_node != null:
        return
    menu_attachment = _create_attachment(skeleton, &"Menu_Hold", &"MenuAttachment")
    if menu_attachment:
        menu_node = MENU_SCENE.instantiate() as Node3D
        menu_attachment.add_child(menu_node)
        _menu_read_target = Marker3D.new()
        _menu_read_target.name = "MenuReadTarget"
        menu_node.add_child(_menu_read_target)
        set_menu_pose(MENU_POSE_HOLD)
        menu_node.visible = false

    phone_attachment = _create_attachment(skeleton, &"Phone_Hold", &"PhoneAttachment")
    if phone_attachment:
        phone_node = PHONE_SCENE.instantiate() as Node3D
        phone_attachment.add_child(phone_node)
        _apply_phone_review_pose()
        phone_node.visible = false

    spoon_attachment = _create_attachment(skeleton, &"Spoon_R", &"SpoonAttachment")
    if spoon_attachment:
        spoon_node = SPOON_SCENE.instantiate() as Node3D
        spoon_attachment.add_child(spoon_node)
        _apply_spoon_pose()
        spoon_node.visible = false

    payment_card_attachment = _create_attachment(skeleton, payment_card_bone, &"PaymentCardAttachment")
    if payment_card_attachment:
        payment_card_node = PAYMENT_CARD_SCENE.instantiate() as Node3D
        payment_card_attachment.add_child(payment_card_node)
        _style_payment_card()
        _add_payment_card_readability_face()
        _apply_payment_card_pose()
        payment_card_node.visible = false


func set_menu_visible(visible_value: bool, pose: StringName = MENU_POSE_HOLD) -> void:
    if menu_node == null:
        return
    set_menu_pose(pose)
    menu_node.visible = visible_value


func set_menu_pose(pose: StringName) -> void:
    if menu_node == null:
        return
    match pose:
        MENU_POSE_READ:
            _apply_menu_pose(menu_read_position, menu_read_rotation_degrees)
        MENU_POSE_CALL:
            _apply_menu_pose(menu_call_position, menu_call_rotation_degrees)
        MENU_POSE_PUT_AWAY:
            _apply_menu_pose(menu_hold_position, menu_hold_rotation_degrees)
        _:
            _apply_menu_pose(menu_hold_position, menu_hold_rotation_degrees)


func get_menu_read_target() -> Marker3D:
    return _menu_read_target


func set_phone_review_visible(visible_value: bool) -> void:
    if phone_node == null:
        return
    _apply_phone_review_pose()
    phone_node.visible = visible_value


func set_spoon_visible(visible_value: bool) -> void:
    if spoon_node == null:
        return
    _apply_spoon_pose()
    spoon_node.visible = visible_value


func set_payment_card_visible(visible_value: bool) -> void:
    if payment_card_node == null:
        return
    _apply_payment_card_pose()
    payment_card_node.visible = visible_value


func is_payment_card_visible() -> bool:
    return payment_card_node != null and payment_card_node.visible


func _apply_menu_pose(local_position: Vector3, local_rotation_degrees: Vector3) -> void:
    menu_node.position = local_position
    menu_node.rotation_degrees = local_rotation_degrees
    menu_node.scale = menu_scale


func _apply_phone_review_pose() -> void:
    phone_node.position = phone_review_position
    phone_node.rotation_degrees = phone_review_rotation_degrees
    phone_node.scale = phone_scale


func _apply_spoon_pose() -> void:
    spoon_node.position = spoon_position
    spoon_node.rotation_degrees = spoon_rotation_degrees
    spoon_node.scale = spoon_scale


func _apply_payment_card_pose() -> void:
    payment_card_node.position = payment_card_position
    payment_card_node.rotation_degrees = payment_card_rotation_degrees
    payment_card_node.scale = payment_card_scale


func _style_payment_card() -> void:
    # The imported card has very dark PBR defaults. Keep the source GLB intact,
    # but give the held prop a readable flat game-material treatment.
    _set_card_mesh_color(&"Card_Body", Color("#2f9290"))
    _set_card_mesh_color(&"Card_Accent", Color("#f05b75"))
    _set_card_mesh_color(&"Card_BackStripe", Color("#fff0c8"))
    _set_card_mesh_color(&"Card_Chip", Color("#f4ce61"))


func _add_payment_card_readability_face() -> void:
    var face := MeshInstance3D.new()
    face.name = "PaymentCardReadableFace"
    var face_mesh := QuadMesh.new()
    face_mesh.size = Vector2(0.084, 0.052)
    face.mesh = face_mesh
    face.position.z = 0.002
    var face_material := StandardMaterial3D.new()
    face_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    face_material.albedo_color = Color("#2f9290")
    face_material.cull_mode = BaseMaterial3D.CULL_DISABLED
    face.material_override = face_material
    payment_card_node.add_child(face)

    var chip := MeshInstance3D.new()
    chip.name = "PaymentCardReadableChip"
    var chip_mesh := BoxMesh.new()
    chip_mesh.size = Vector3(0.019, 0.014, 0.002)
    chip.mesh = chip_mesh
    chip.position = Vector3(-0.014, 0.006, 0.004)
    var chip_material := StandardMaterial3D.new()
    chip_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    chip_material.albedo_color = Color("#f4ce61")
    chip.material_override = chip_material
    payment_card_node.add_child(chip)


func _set_card_mesh_color(mesh_name: StringName, color: Color) -> void:
    var mesh := payment_card_node.find_child(mesh_name, true, false) as MeshInstance3D
    if mesh == null:
        return
    var material := StandardMaterial3D.new()
    material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    material.albedo_color = color
    material.cull_mode = BaseMaterial3D.CULL_DISABLED
    mesh.material_override = material


func _create_attachment(skeleton: Skeleton3D, bone_name: StringName, attachment_name: StringName) -> BoneAttachment3D:
    if skeleton.find_bone(bone_name) < 0:
        push_warning("Customer prop attachment is missing bone %s" % bone_name)
        return null
    var attachment := BoneAttachment3D.new()
    attachment.name = attachment_name
    attachment.bone_name = bone_name
    skeleton.add_child(attachment)
    return attachment
