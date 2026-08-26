extends SceneTree

const MAIN_SCENE := preload("res://scenes/main.tscn")
const GRAVITY := 9.8
const WALK_SPEED := 3.0
const MAX_STEPS := 240

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var main := MAIN_SCENE.instantiate()
	root.add_child(main)
	await process_frame

	var player := main.get_node_or_null("Player") as CharacterBody3D
	if player == null:
		push_error("Traversal failed: Player path missing")
		quit(1)
		return

	player.set_process(false)
	player.set_physics_process(false)
	var failures: Array[String] = []

	if not await _walk_to_z(player, Vector3(0, 0.05, 10.2), 14.4):
		failures.append("center doorway")
	if not await _walk_to_z(player, Vector3(0, 0.05, 14.4), 18.2):
		failures.append("near curb ramp")
	if not await _walk_to_z(player, Vector3(0, -0.10, 23.0), 27.2):
		failures.append("far curb ramp")

	if failures.is_empty():
		print("PASS: player crosses doorway and both curb ramps without jumping.")
		quit(0)
	else:
		push_error("Traversal blocked at: %s" % ", ".join(failures))
		quit(1)

func _walk_to_z(player: CharacterBody3D, start: Vector3, target_z: float) -> bool:
	player.global_position = start
	player.velocity = Vector3.ZERO
	await physics_frame
	await physics_frame

	for _step in MAX_STEPS:
		player.velocity.x = 0.0
		player.velocity.z = WALK_SPEED
		if player.is_on_floor():
			player.velocity.y = -0.1
		else:
			player.velocity.y -= GRAVITY / 60.0
		player.move_and_slide()
		await physics_frame
		if player.global_position.z >= target_z:
			return true
		if player.global_position.y < -2.0:
			return false
	return false
