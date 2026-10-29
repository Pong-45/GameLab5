extends Node3D
## Adapt the astronaut's own rig animations to the controller's animation names.
const MODEL = preload("res://Assets/Models/astronaut/astronaut.glb")

func _ready() -> void:
	var visual: Node3D = MODEL.instantiate()
	visual.name = "Visual"
	$FlipPivot.add_child(visual)
	var source := visual.find_child("AnimationPlayer", true, false) as AnimationPlayer
	assert(source != null, "Astronaut requires embedded animations")
	var source_root := source.get_node(source.root_node)
	var library := AnimationLibrary.new()
	var aliases := {"Idle": "Idle", "Run": "Run", "Walk": "Walk", "Jump": "Jump_Idle", "Fall": "Jump_Idle", "Flip": "Jump_Idle"}
	for alias in aliases:
		var clip: Animation
		for clip_name in source.get_animation_list():
			if String(clip_name).get_slice("|", 1) == aliases[alias] or String(clip_name) == aliases[alias]:
				clip = source.get_animation(clip_name).duplicate(true)
				break
		assert(clip != null, "Missing astronaut animation: " + aliases[alias])
		for track in range(clip.get_track_count()):
			var old_path := clip.track_get_path(track)
			var target := source_root.get_node(NodePath(old_path.get_concatenated_names()))
			var path := String(get_path_to(target))
			if old_path.get_subname_count() > 0:
				path += ":" + old_path.get_concatenated_subnames()
			clip.track_set_path(track, NodePath(path))
		clip.loop_mode = Animation.LOOP_LINEAR
		var rotation_track := clip.add_track(Animation.TYPE_VALUE)
		clip.track_set_path(rotation_track, NodePath("FlipPivot:rotation:x"))
		clip.track_insert_key(rotation_track, 0.0, 0.0)
		if alias == "Flip":
			clip.length = 0.533333
			clip.loop_mode = Animation.LOOP_NONE
			clip.track_insert_key(rotation_track, clip.length, -TAU)
		library.add_animation(alias, clip)
	source.stop()
	source.active = false
	$AnimationPlayer.add_animation_library("", library)
	$AnimationPlayer.play("Idle")
	$AnimationPlayer.advance(0.0)
	# Fit the visual to the existing 1.4 m capsule and keep its feet at ground level.
	var bounds := AABB()
	var first := true
	for mesh in visual.find_children("*", "MeshInstance3D", true, false):
		var box: AABB = (visual.global_transform.affine_inverse() * mesh.global_transform) * mesh.get_aabb()
		bounds = box if first else bounds.merge(box)
		first = false
	assert(not first and bounds.size.y > 0.0, "Astronaut has no visible mesh")
	var factor := 1.4 / bounds.size.y
	visual.scale *= factor
	visual.position = Vector3(-bounds.get_center().x * factor, -0.7 - bounds.position.y * factor, -bounds.get_center().z * factor)
