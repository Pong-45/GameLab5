extends SceneTree
var world
func _initialize() -> void:
	call_deferred("verify")
func verify() -> void:
	world = load("res://Scenes/timewild.tscn").instantiate()
	root.add_child(world)
	await physics_frame
	world.player.set_physics_process(false)
	# Closed gates cannot advance; damage has a cooldown and respawns at the anchor.
	world.player.position = Vector3(0, 0, -61)
	world._process(0.01)
	assert(world.stage == 0 and not world.finished)
	world.player.position = Vector3(0, 0, -34)
	world._process(0.01)
	assert(world.checkpoint_active)
	world.hurt("Test patrol damage")
	assert(world.health == 2 and world.player.position == world.checkpoint)
	world.hurt("Cooldown")
	assert(world.health == 2)
	world.immunity = 0
	world.hurt("Second hit")
	world.immunity = 0
	world.hurt("Third hit")
	assert(world.dead and world.health == 0 and world.overlay.visible)
	world.restart()
	assert(world.health == 3 and not world.dead and world.collected == 0)
	for sector in range(3):
		world.player.set_physics_process(false)
		assert(world.stage == sector)
		assert(world.shards.size() == 6)
		assert(world.traps.size() == 3 + sector)
		for shard in world.shards.duplicate():
			world.player.position = shard.position
			world._process(0.01)
		assert(world.collected == 6 and world.shards.is_empty())
		world.player.position = Vector3(0, 0, -61)
		world._process(0.01)
	assert(world.finished and world.overlay.visible)
	world.restart()
	assert(world.stage == 0 and not world.finished)
	world.player.set_physics_process(false)
	# Walk the entire traversable route using physics and jump across the river.
	world.player.position = Vector3(2, 0.3, -23.5)
	for step in range(100):
		world.player.velocity = Vector3(0, world.player.velocity.y - 19.6 / 60, -4)
		if step == 12:
			world.player.velocity.y = 6
		if step == 35:
			world.player.velocity.y = 6
		world.player.move_and_slide()
		await physics_frame
	assert(world.player.position.z < -29.5 and world.player.position.y > -1.0, str(world.player.position))
	print("PASS: gate lock, checkpoint, damage cooldown, death/restart, 18 pickups, 3 sectors, victory/replay, physical river crossing")
	world.queue_free()
	await process_frame
	quit()
