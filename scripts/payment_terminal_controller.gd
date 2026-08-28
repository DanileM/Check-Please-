class_name PaymentTerminalController
extends PickupItem

signal payment_approved(target: Node3D, charged_amount_cents: int)
signal payment_rejected(charged_amount_cents: int)

@export_group("Terminal Interaction")
@export var interaction_position := Vector3(-0.05, -0.13, -0.70)
@export var interaction_rotation_degrees := Vector3(-9.0, 0.0, 0.0)
@export var interaction_scale := Vector3(3.0, 3.0, 3.0)
@export var transition_duration := 0.24
@export var result_message_duration := 0.8
@export var maximum_amount_cents := 999999
@export_flags_3d_physics var button_collision_layer := 4

var entered_amount_cents := 0
var payment_target: Node3D
var _interacting := false
var _temporary_screen_text := ""
var _screen_message_token := 0
var _screen_viewport: SubViewport
var _screen_label: Label


func _ready() -> void:

    super._ready()
    _build_screen()
    _set_terminal_buttons_enabled(false)


func is_payment_terminal() -> bool:

    return true


func get_tooltip_text() -> String:

    return "Payment Terminal"


func pick_up_to(carry_anchor: Node3D) -> bool:

    var picked_up := super.pick_up_to(carry_anchor)
    if picked_up:
        _set_terminal_buttons_enabled(false)
    return picked_up


func begin_payment_interaction(target: Node3D) -> bool:

    if not is_held() or target == null:
        return false
    if not target.has_method("get_amount_due_cents") or not target.has_method("complete_payment"):
        return false
    payment_target = target
    _interacting = true
    entered_amount_cents = 0
    _temporary_screen_text = ""
    _set_terminal_buttons_enabled(true)
    _tween_to_pose(interaction_position, interaction_rotation_degrees, interaction_scale)
    _refresh_screen()
    return true


func end_payment_interaction() -> void:

    _interacting = false
    payment_target = null
    _temporary_screen_text = ""
    _screen_message_token += 1
    _set_terminal_buttons_enabled(false)
    if is_held():
        _tween_to_pose(carry_position, carry_rotation_degrees, carry_scale)
    _refresh_screen()


func is_payment_interaction_active() -> bool:

    return _interacting


func get_entered_cents() -> int:

    return entered_amount_cents


func get_display_text() -> String:

    if not _temporary_screen_text.is_empty():
        return _temporary_screen_text
    return "$%d.%02d" % [int(entered_amount_cents / 100), entered_amount_cents % 100]


func press_button(action: String) -> void:

    if not _interacting:
        return
    if action.length() == 1 and "0123456789".contains(action):
        entered_amount_cents = mini(entered_amount_cents * 10 + action.to_int(), maximum_amount_cents)
        _temporary_screen_text = ""
        _refresh_screen()
        return
    match action:
        "X":
            entered_amount_cents = 0
            _temporary_screen_text = ""
            _refresh_screen()
        "<":
            entered_amount_cents = int(entered_amount_cents / 10)
            _temporary_screen_text = ""
            _refresh_screen()
        "CHARGE":
            _attempt_charge()


func click_from_camera(camera: Camera3D, screen_position := Vector2(-1.0, -1.0)) -> bool:

    if not _interacting or camera == null or get_world_3d() == null:
        return false
    var click_position := screen_position
    if click_position.x < 0.0 or click_position.y < 0.0:
        click_position = get_viewport().get_mouse_position()
    var ray_origin := camera.project_ray_origin(click_position)
    var ray_end := ray_origin + camera.project_ray_normal(click_position) * 2.0
    var query := PhysicsRayQueryParameters3D.create(ray_origin, ray_end, button_collision_layer)
    query.collide_with_areas = true
    query.collide_with_bodies = false
    var result := get_world_3d().direct_space_state.intersect_ray(query)
    var node := result.get("collider") as Node
    while node:
        if node.has_meta("terminal_action"):
            press_button(String(node.get_meta("terminal_action")))
            return true
        node = node.get_parent()
    return false


func _attempt_charge() -> void:

    if payment_target == null or not is_instance_valid(payment_target):
        return
    if payment_target.complete_payment(entered_amount_cents):
        _show_temporary_screen_text("APPROVED")
        _finish_approval_after_message(payment_target, entered_amount_cents)
    else:
        _show_temporary_screen_text("INCORRECT AMOUNT")
        payment_rejected.emit(entered_amount_cents)


func _finish_approval_after_message(target: Node3D, charged_amount_cents: int) -> void:

    await get_tree().create_timer(result_message_duration).timeout
    if not is_instance_valid(target):
        return
    payment_approved.emit(target, charged_amount_cents)


func _show_temporary_screen_text(value: String) -> void:

    _temporary_screen_text = value
    _screen_message_token += 1
    var token := _screen_message_token
    _refresh_screen()
    _clear_temporary_screen_text_after_delay(token)


func _clear_temporary_screen_text_after_delay(token: int) -> void:

    await get_tree().create_timer(result_message_duration).timeout
    if token != _screen_message_token:
        return
    _temporary_screen_text = ""
    _refresh_screen()


func _tween_to_pose(next_position: Vector3, next_rotation_degrees: Vector3, next_scale: Vector3) -> void:

    var tween := create_tween()
    tween.set_parallel(true)
    tween.tween_property(self, "position", next_position, transition_duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
    tween.tween_property(self, "rotation_degrees", next_rotation_degrees, transition_duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
    tween.tween_property(self, "scale", next_scale, transition_duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


func _set_terminal_buttons_enabled(enabled: bool) -> void:

    var button_root := get_node_or_null("ButtonHitboxes")
    if button_root == null:
        return
    for child in button_root.get_children():
        if child is CollisionObject3D:
            child.collision_layer = button_collision_layer if enabled else 0
            child.collision_mask = 0


func _build_screen() -> void:

    var screen_mesh := find_child("POS_ScreenInner", true, false) as MeshInstance3D
    if screen_mesh == null:
        push_warning("Payment terminal screen mesh was not found")
        return
    _screen_viewport = SubViewport.new()
    _screen_viewport.name = "TerminalScreenViewport"
    _screen_viewport.size = Vector2i(512, 256)
    _screen_viewport.transparent_bg = false
    _screen_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
    add_child(_screen_viewport)

    var screen_canvas := Control.new()
    screen_canvas.name = "TerminalScreenCanvas"
    screen_canvas.size = Vector2(_screen_viewport.size)
    _screen_viewport.add_child(screen_canvas)
    var background := ColorRect.new()
    background.color = Color("#18252b")
    background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    screen_canvas.add_child(background)
    _screen_label = Label.new()
    _screen_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    _screen_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    _screen_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    _screen_label.add_theme_font_size_override("font_size", 64)
    _screen_label.add_theme_color_override("font_color", Color("#fff0c8"))
    _screen_label.add_theme_color_override("font_outline_color", Color("#2a202c"))
    _screen_label.add_theme_constant_override("outline_size", 7)
    screen_canvas.add_child(_screen_label)

    _add_screen_surface(screen_mesh)
    _refresh_screen()


func _add_screen_surface(reference_screen_mesh: MeshInstance3D) -> void:

    # Imported screen panels can contain layered opaque meshes. A tiny quad in
    # front of the actual panel keeps the live display visible in GL Compatibility
    # without altering the terminal GLB or its authored materials.
    var display_surface := MeshInstance3D.new()
    display_surface.name = "LiveScreenSurface"
    var display_mesh := QuadMesh.new()
    display_mesh.size = Vector2(0.068, 0.039)
    display_surface.mesh = display_mesh
    display_surface.transform = global_transform.affine_inverse() * reference_screen_mesh.global_transform
    display_surface.position += display_surface.transform.basis.z * 0.001
    var screen_material := StandardMaterial3D.new()
    screen_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    screen_material.albedo_texture = _screen_viewport.get_texture()
    screen_material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
    screen_material.cull_mode = BaseMaterial3D.CULL_DISABLED
    display_surface.material_override = screen_material
    add_child(display_surface)


func _refresh_screen() -> void:

    if _screen_label:
        _screen_label.text = get_display_text()
