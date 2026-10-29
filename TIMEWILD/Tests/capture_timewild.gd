extends SceneTree
func _initialize() -> void:
	call_deferred("capture")
func capture() -> void:
	var world = load("res://Scenes/timewild.tscn").instantiate()
	root.add_child(world)
	for frame in range(40):
		await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://Tests/timewild-preview.png")
	world.stage = 2
	world.build_stage()
	world.player.position = Vector3(0, 0.1, -36)
	world.player.get_node("Astronaut").rotation.y = PI
	world.player.get_node("Gimbal").position = world.player.position
	world.immunity = 10
	for frame in range(20):
		await process_frame
	world.player.get_node("Astronaut").show()
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://Tests/timewild-rex-preview.png")
	quit()
