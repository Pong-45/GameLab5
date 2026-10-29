extends RefCounted
## Shared scenes and geometry; repeated scenery reuses imported mesh resources.
static var cache: Dictionary = {}

static func model(file: String, height: float, motion: String = "") -> Node3D:
	if not cache.has(file):
		cache[file] = load("res://Assets/Prehistoric/" + file)
	var holder := Node3D.new()
	var visual: Node3D = cache[file].instantiate()
	holder.add_child(visual)
	var box := AABB()
	var first := true
	for mesh in visual.find_children("*", "MeshInstance3D", true, false):
		var transform_to_root := Transform3D.IDENTITY
		var cursor: Node3D = mesh
		while cursor != visual:
			transform_to_root = cursor.transform * transform_to_root
			cursor = cursor.get_parent()
		transform_to_root = visual.transform * transform_to_root
		var bounds: AABB = transform_to_root * mesh.get_aabb()
		box = bounds if first else box.merge(bounds)
		first = false
	var factor := height / maxf(box.size.y, 0.01)
	visual.scale *= factor
	visual.position += Vector3(-box.get_center().x, -box.position.y, -box.get_center().z) * factor
	var animator := visual.find_child("AnimationPlayer", true, false) as AnimationPlayer
	if animator:
		for clip in animator.get_animation_list():
			if motion != "" and String(clip).ends_with(motion):
				animator.get_animation(clip).loop_mode = Animation.LOOP_LINEAR
				animator.play(clip)
				break
	return holder

static func material(color: Color, glow: float = 0.0) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.9
	if glow > 0:
		mat.emission_enabled = true
		mat.emission = color
		mat.emission_energy_multiplier = glow
	return mat

static func mesh(parent: Node3D, shape: Mesh, at: Vector3, mat: Material) -> MeshInstance3D:
	var item := MeshInstance3D.new()
	item.mesh = shape
	item.material_override = mat
	parent.add_child(item)
	item.position = at
	return item

static func block(parent: Node3D, at: Vector3, size: Vector3, mat: Material, solid: bool = true) -> Node3D:
	var body := StaticBody3D.new()
	parent.add_child(body)
	body.position = at
	var cube := BoxMesh.new()
	cube.size = size
	mesh(body, cube, Vector3.ZERO, mat)
	if solid:
		var collider := CollisionShape3D.new()
		var shape := BoxShape3D.new()
		shape.size = size
		collider.shape = shape
		body.add_child(collider)
	return body
