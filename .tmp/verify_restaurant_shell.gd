extends SceneTree

const STOREFRONT_SCENE := preload("res://scenes/restaurant/storefront_exterior.tscn")
const PLAYER_RADIUS := 0.34

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var storefront := STOREFRONT_SCENE.instantiate()
	root.add_child(storefront)
	await process_frame

	var corridor_min := Vector3(-PLAYER_RADIUS, 0.05, 11.84)
	var corridor_max := Vector3(PLAYER_RADIUS, 2.90, 12.16)
	var blockers: Array[String] = []
	for collision_node in storefront.find_children("*", "CollisionShape3D", true, false):
		var collision := collision_node as CollisionShape3D
		if collision == null or not collision.shape is BoxShape3D:
			continue
		var shape := collision.shape as BoxShape3D
		var half_size := shape.size * collision.global_basis.get_scale() * 0.5
		var box_min := collision.global_position - half_size
		var box_max := collision.global_position + half_size
		if _overlaps(box_min, box_max, corridor_min, corridor_max):
			blockers.append(str(collision.get_path()))

	var left_glass := storefront.get_node_or_null("Facade/FacadeCollision/WindowGlassLeft") as CollisionShape3D
	var right_glass := storefront.get_node_or_null("Facade/FacadeCollision/WindowGlassRight") as CollisionShape3D
	if left_glass == null or left_glass.shape == null:
		blockers.append("missing left window collision")
	if right_glass == null or right_glass.shape == null:
		blockers.append("missing right window collision")

	if blockers.is_empty():
		print("PASS: 0.68 m player corridor is open; both window collisions exist.")
		quit(0)
	else:
		push_error("Storefront geometry failed: %s" % ", ".join(blockers))
		quit(1)

func _overlaps(a_min: Vector3, a_max: Vector3, b_min: Vector3, b_max: Vector3) -> bool:
	return a_min.x < b_max.x and a_max.x > b_min.x \
		and a_min.y < b_max.y and a_max.y > b_min.y \
		and a_min.z < b_max.z and a_max.z > b_min.z
