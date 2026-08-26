extends CharacterBody3D

@export var move_speed := 4.2
@export var mouse_sensitivity := 0.0022
@export var acceleration := 14.0
@export var interaction_distance := 3.0

@onready var head: Node3D = $Head
@onready var camera: Camera3D = $Head/Camera3D
@onready var ray: RayCast3D = $Head/Camera3D/InteractRay
@onready var hint: Label = $HUD/Hint

var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")

func _ready() -> void:
    Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
    hint.text = "WASD — move    E — inspect    ESC — mouse"

func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
        rotate_y(-event.relative.x * mouse_sensitivity)
        head.rotate_x(-event.relative.y * mouse_sensitivity)
        head.rotation.x = clamp(head.rotation.x, deg_to_rad(-82.0), deg_to_rad(82.0))
    elif event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
        Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED else Input.MOUSE_MODE_CAPTURED
    elif event is InputEventMouseButton and event.pressed and Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
        Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _physics_process(delta: float) -> void:
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

    if Input.is_physical_key_pressed(KEY_E):
        _inspect()

func _inspect() -> void:
    if not ray.is_colliding():
        return
    var collider := ray.get_collider()
    if collider == null:
        return
    var target_node: Node = collider
    while target_node != null:
        if target_node.is_in_group("table_station"):
            hint.text = "Table station — service hooks are ready"
            return
        target_node = target_node.get_parent()
