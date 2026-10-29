extends SceneTree

func _initialize() -> void:
	call_deferred("verify")

func verify() -> void:
	var model = load("res://Assets/Models/astronaut/astronaut.tscn").instantiate()
	root.add_child(model)
	var player: AnimationPlayer = model.get_node("AnimationPlayer")
	for name in ["Idle", "Run", "Walk", "Jump", "Fall", "Flip"]:
		assert(player.has_animation(name))
		var clip := player.get_animation(name)
		for track in range(clip.get_track_count()):
			var path := clip.track_get_path(track)
			assert(model.has_node(NodePath(path.get_concatenated_names())), str(path))
		player.play(name, 0.0)
		player.advance(clip.length * 0.5)
		if name == "Flip":
			assert(abs(model.get_node("FlipPivot").rotation.x + PI) < 0.01)
	player.play("Idle", 0.0)
	player.advance(0.0)
	assert(is_zero_approx(model.get_node("FlipPivot").rotation.x))
	assert(model.get_node("FlipPivot/Visual").scale.y > 0.0)
	print("PASS: astronaut animation paths, all six states, flip midpoint and landing reset")
	model.queue_free()
	await process_frame
	quit()
