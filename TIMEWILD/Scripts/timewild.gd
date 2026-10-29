extends Node3D
## Three handcrafted routes share a small palette of instanced low-poly assets.
const Art = preload("res://Scripts/prehistoric_assets.gd")
const Patrol = preload("res://Scripts/dinosaur_patrol.gd")
const PLAYER = preload("res://Scenes/player.tscn")
const TITLES = ["01 / THE LOST CANOPY", "02 / RAPTOR CROSSING", "03 / THE LAST RIFT"]
const TOTAL_SHARDS = 6
var stage := 0
var collected := 0
var health := 3
var immunity := 0.0
var elapsed := 0.0
var finished := false
var dead := false
var checkpoint := Vector3(0, 0.1, 3)
var checkpoint_active := false
var player: CharacterBody3D
var terrain: Node3D
var portal: Node3D
var portal_core: MeshInstance3D
var shards: Array[Node3D] = []
var traps: Array[Node3D] = []
var hud: CanvasLayer
var counter: Label
var status: Label
var subtitle: Label
var toast: Label
var toast_time := 0.0
var progress: ProgressBar
var overlay: PanelContainer
var overlay_title: Label
var overlay_text: Label
var resume_button: Button
var paused := false
var rng := RandomNumberGenerator.new()
var green := Art.material(Color("386a4f"))
var earth := Art.material(Color("594c3c"))
var sand := Art.material(Color("b5a176"))
var dark := Art.material(Color("243b37"))
var cyan := Art.material(Color("6ce8df"), 1.4)
var amber := Art.material(Color("ffb65a"), 0.7)
var red := Art.material(Color("e97359"), 0.4)
var water := Art.material(Color("287c89"), 0.15)

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	make_environment()
	make_hud()
	build_stage()

func make_environment() -> void:
	var environment := WorldEnvironment.new()
	var settings := Environment.new()
	settings.background_mode = Environment.BG_SKY
	var sky := Sky.new()
	var atmosphere := ProceduralSkyMaterial.new()
	atmosphere.sky_top_color = Color("224d61")
	atmosphere.sky_horizon_color = Color("bbd6bf")
	atmosphere.ground_horizon_color = Color("bbd6bf")
	atmosphere.ground_bottom_color = Color("344e47")
	sky.sky_material = atmosphere
	settings.sky = sky
	settings.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	settings.ambient_light_color = Color("b9d6c5")
	settings.ambient_light_energy = 0.45
	settings.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	settings.fog_enabled = true
	settings.fog_light_color = Color("91b6a1")
	settings.fog_density = 0.007
	environment.environment = settings
	add_child(environment)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-48, -28, 0)
	sun.light_color = Color("ffe5af")
	sun.light_energy = 0.85
	sun.shadow_enabled = true
	add_child(sun)

func build_stage() -> void:
	if is_instance_valid(terrain):
		remove_child(terrain)
		terrain.queue_free()
	if is_instance_valid(player):
		remove_child(player)
		player.queue_free()
	shards.clear()
	traps.clear()
	collected = 0
	health = 3
	immunity = 0.0
	dead = false
	finished = false
	checkpoint_active = false
	checkpoint = Vector3(0, 0.1, 3)
	terrain = Node3D.new()
	terrain.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(terrain)
	rng.seed = 7342 + stage * 119
	green = Art.material([Color("386a4f"), Color("506548"), Color("4d5c58")][stage])
	sand = Art.material([Color("a8946a"), Color("b6926e"), Color("999b85")][stage])
	# Split ground around a river: the stepping stones form the only safe crossing.
	Art.block(terrain, Vector3(0, -1, -9), Vector3(28, 2, 32), green)
	Art.block(terrain, Vector3(0, -1, -47), Vector3(28, 2, 34), green)
	Art.block(terrain, Vector3(0, -1.5, -27.5), Vector3(28, 0.2, 5), water, false)
	Art.block(terrain, Vector3(0, -3, -28), Vector3(28, 3, 76), earth, false)
	for z in range(3, -64, -3):
		if z < -24 and z > -31:
			continue
		Art.block(terrain, Vector3(sin(z * 0.1) * 1.5, 0.012, z), Vector3(6, 0.025, 2.95), sand, false)
	for point in [Vector3(2, -0.1, -25.5), Vector3(3.4, 0.05, -27.5), Vector3(2, -0.1, -29.5)]:
		Art.block(terrain, point, Vector3(2.4, 0.5, 1.75), dark)
		Art.block(terrain, point + Vector3(0, 0.26, 0), Vector3(2.15, 0.02, 1.5), sand, false)
	# Solid boulders and low fallen trunks make the route weave and jump.
	for at in [Vector3(-1.8, 0, -10), Vector3(2.3, 0, -38), Vector3(-2.5, 0, -53)]:
		var rock := Art.model("Nature/Rock Medium.glb", 1.7)
		terrain.add_child(rock)
		rock.position = at
		var body := StaticBody3D.new()
		rock.add_child(body)
		var hit := CollisionShape3D.new()
		var sphere := SphereShape3D.new()
		sphere.radius = 1.0
		hit.shape = sphere
		hit.position.y = 0.7
		body.add_child(hit)
	for z in [-17, -48]:
		Art.block(terrain, Vector3(0.4, 0.28, z), Vector3(3.8, 0.56, 0.65), earth)
	for index in range(3 + stage):
		var patch := Node3D.new()
		terrain.add_child(patch)
		patch.position = Vector3(-3.8 if index % 2 == 0 else 3.4, 0, -13 - index * 9)
		patch.set_meta("phase", index * 1.7)
		Art.block(patch, Vector3(0, 0.04, 0), Vector3(2.6, 0.08, 2.6), red, false)
		for x in [-0.75, 0.0, 0.75]:
			for z in [-0.75, 0.0, 0.75]:
				var cone := CylinderMesh.new()
				cone.top_radius = 0
				cone.bottom_radius = 0.2
				cone.height = 0.8
				cone.radial_segments = 5
				Art.mesh(patch, cone, Vector3(x, 0.4, z), amber)
		traps.append(patch)
	for at in [Vector3(-2, 1.15, -5), Vector3(3.5, 1.15, -15), Vector3(-3.5, 1.15, -22), Vector3(2, 1.15, -33), Vector3(-3.5, 1.15, -44), Vector3(3, 1.15, -56)]:
		make_shard(at)
	decorate()
	make_dinosaur("Velociraptor", Vector3(-6, 0, -20), Vector3(6, 0, -20), 1.65, 2.2 + stage * 0.5, true)
	make_dinosaur("T-Rex" if stage == 2 else "Velociraptor", Vector3(6, 0, -43), Vector3(-6, 0, -43), 3.3 if stage == 2 else 1.7, 2.0 + stage * 0.65, true)
	if stage > 0:
		make_dinosaur("Velociraptor", Vector3(-4, 0, -52), Vector3(5, 0, -56), 1.6, 2.8, true)
	make_dinosaur("Apatosaurus", Vector3(-10, 0, -35), Vector3(-10, 0, -48), 5.5, 0.65, false)
	make_dinosaur("Triceratops", Vector3(9, 0, -8), Vector3(9, 0, -18), 2.5, 0.85, false)
	make_portal()
	make_sign(Vector3(0, 2.8, 0), "TEMPORAL SIGNAL LOST\nFind all 6 chronoshards", Color("b9fff0"))
	make_sign(Vector3(0, 2.3, -23), "RIVER CROSSING  >\nUse the stepping stones", Color("ffcf88"))
	make_sign(Vector3(-4, 1.8, -34), "ANCHOR POINT", Color("8affd7"))
	Art.block(terrain, Vector3(-4, 0.08, -34), Vector3(2, 0.16, 2), cyan, false)
	player = PLAYER.instantiate()
	player.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(player)
	player.position = checkpoint
	player.get_node("Gimbal").position = checkpoint + Vector3.UP
	player.get_node("Gimbal/Camera3D").far = 160
	player.get_node("Gimbal/Camera3D").fov = 72
	GameManager.score = 0
	subtitle.text = TITLES[stage]
	overlay.hide()
	message("Your time machine is broken. Recover 6 chronoshards to power the rift.", 7)
	update_hud()

func decorate() -> void:
	for side in [-1, 1]:
		for index in range(19):
			var at := Vector3(side * rng.randf_range(8, 12.5), 0, 5 - index * 3.7)
			if at.z > -30 and at.z < -25:
				continue
			var tree := Art.model("Nature/Tree.glb" if index % 3 else "Nature/Pine.glb", rng.randf_range(5, 8))
			terrain.add_child(tree)
			tree.position = at
			tree.rotation.y = rng.randf_range(0, TAU)
		for index in range(32):
			var z := rng.randf_range(-62, 5)
			if z > -31 and z < -24:
				continue
			var file: String = ["Fern", "Bush", "Grass", "Flower Petal"][index % 4]
			var plant := Art.model("Nature/" + file + ".glb", rng.randf_range(0.45, 1.3))
			terrain.add_child(plant)
			plant.position = Vector3(side * rng.randf_range(5.5, 12), 0, z)
			plant.rotation.y = rng.randf_range(0, TAU)
	# Distant faceted mountains give the valley a silhouette without more textures.
	for index in range(12):
		var mountain := CylinderMesh.new()
		mountain.top_radius = 0
		mountain.bottom_radius = rng.randf_range(8, 15)
		mountain.height = rng.randf_range(12, 24)
		mountain.radial_segments = 5
		Art.mesh(terrain, mountain, Vector3(-25 if index % 2 == 0 else 25, mountain.height / 2 - 4, 14 - index * 8), dark)
	# Rail-like basalt edges keep the camera corridor readable and prevent shortcuts outside the island.
	for x in [-14.4, 14.4]:
		var boundary := Art.block(terrain, Vector3(x, 1, -28), Vector3(1, 4, 76), dark)
		boundary.get_child(0).hide()
		for z in range(4, -65, -6):
			var rock := Art.model("Nature/Rock Medium.glb", rng.randf_range(2.0, 3.5))
			terrain.add_child(rock)
			rock.position = Vector3(x, -0.2, z)
			rock.rotation.y = rng.randf_range(0, TAU)
	var back_wall := Art.block(terrain, Vector3(0, 1, 7.5), Vector3(29, 4, 1), dark)
	back_wall.get_child(0).hide()
	var end_wall := Art.block(terrain, Vector3(0, 1, -64.5), Vector3(29, 4, 1), dark)
	end_wall.get_child(0).hide()

func make_dinosaur(kind: String, a: Vector3, b: Vector3, height: float, speed: float, danger: bool) -> void:
	var dino := Node3D.new()
	dino.set_script(Patrol)
	dino.world = self
	dino.route_start = a
	dino.route_end = b
	dino.pace = speed
	dino.dangerous = danger
	terrain.add_child(dino)
	dino.position = a
	var visual := Art.model("Dinosaurs/" + kind + ".glb", height, "Walk" if speed < 1 else "Run")
	dino.add_child(visual)
	if danger:
		var ring := TorusMesh.new()
		ring.inner_radius = 1.25
		ring.outer_radius = 1.38
		ring.rings = 16
		ring.ring_segments = 6
		Art.mesh(dino, ring, Vector3(0, 0.05, 0), red)

func make_shard(at: Vector3) -> void:
	var shard := Node3D.new()
	terrain.add_child(shard)
	shard.position = at
	shard.set_meta("base_y", at.y)
	var crystal := PrismMesh.new()
	crystal.size = Vector3(0.5, 0.85, 0.5)
	var gem := Art.mesh(shard, crystal, Vector3.ZERO, cyan)
	gem.rotation.z = PI
	var ring := TorusMesh.new()
	ring.inner_radius = 0.48
	ring.outer_radius = 0.53
	ring.rings = 12
	ring.ring_segments = 5
	Art.mesh(shard, ring, Vector3(0, -0.65, 0), cyan)
	shards.append(shard)

func make_portal() -> void:
	portal = Node3D.new()
	terrain.add_child(portal)
	portal.position = Vector3(0, 0, -61)
	Art.block(portal, Vector3(0, 0.1, 0), Vector3(5.5, 0.2, 3), dark)
	for x in [-2.1, 2.1]:
		Art.block(portal, Vector3(x, 1.7, 0), Vector3(0.75, 3.4, 1), dark)
		Art.block(portal, Vector3(x, 1.7, 0.53), Vector3(0.14, 2.6, 0.04), cyan, false)
	Art.block(portal, Vector3(0, 3.6, 0), Vector3(5.1, 0.7, 1.1), dark)
	var disc := CylinderMesh.new()
	disc.top_radius = 1.65
	disc.bottom_radius = 1.65
	disc.height = 0.08
	disc.radial_segments = 32
	portal_core = Art.mesh(portal, disc, Vector3(0, 1.85, 0), amber)
	portal_core.rotation.x = PI / 2
	make_sign(Vector3(0, 4.8, -61), "TEMPORAL RIFT\n6 CHRONOSHARDS REQUIRED", Color("b9fff0"))

func make_sign(at: Vector3, text: String, color: Color) -> void:
	var label := Label3D.new()
	label.text = text
	label.font_size = 32
	label.pixel_size = 0.009
	label.modulate = color
	label.outline_size = 6
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	terrain.add_child(label)
	label.position = at

func _process(delta: float) -> void:
	if paused or dead or finished:
		return
	elapsed += delta
	immunity = maxf(0, immunity - delta)
	toast_time -= delta
	toast.modulate.a = clampf(toast_time, 0, 1)
	player.get_node("Astronaut").visible = immunity <= 0 or int(immunity * 12) % 2 == 0
	for shard in shards.duplicate():
		shard.rotation.y += delta * 1.4
		shard.position.y = float(shard.get_meta("base_y")) + sin(elapsed * 3 + shard.position.z) * 0.15
		if player.position.distance_to(shard.position) < 1.5:
			shards.erase(shard)
			shard.queue_free()
			collected += 1
			AudioManager.coin_sfx.play()
			if collected == TOTAL_SHARDS:
				portal_core.material_override = cyan
				message("RIFT ONLINE / All chronoshards recovered. Head to the cyan gate!", 5)
			update_hud()
	for trap in traps:
		var active := fmod(elapsed + float(trap.get_meta("phase")), 3.6) < 2.1
		for child in trap.get_children():
			if child is MeshInstance3D:
				child.scale.y = 1.0 if active else 0.12
		if active and abs(player.position.x - trap.position.x) < 1.55 and abs(player.position.z - trap.position.z) < 1.55 and player.position.y < 0.85:
			hurt("Spike trap! Wait for the spikes to retract, or jump over them.")
	if player.position.y < -2.2:
		hurt("You fell into the river. Cross using the stepping stones.", true)
	if not checkpoint_active and player.position.z < -32 and player.position.y > -0.1:
		checkpoint_active = true
		checkpoint = Vector3(-4, 0.2, -34)
		message("ANCHOR SAVED / You will return here if you are caught.", 4)
	if abs(player.position.x) < 1.8 and abs(player.position.z + 61) < 1.5 and player.position.y < 2:
		if collected == TOTAL_SHARDS:
			advance_stage()
		elif toast_time < 0.5:
			message("Rift offline / Find %d more chronoshards." % (TOTAL_SHARDS - collected), 3)
	progress.value = clampf(-player.position.z / 61.0 * 100, 0, 100)

func hurt(reason: String, force_respawn: bool = false) -> void:
	if dead or finished:
		return
	if immunity > 0 and not force_respawn:
		return
	if immunity <= 0:
		health -= 1
	immunity = 2.0
	player.velocity = Vector3.ZERO
	player.position = checkpoint
	player.get_node("Gimbal").position = checkpoint + Vector3.UP
	player.get_node("Astronaut").show()
	update_hud()
	message(reason, 4)
	if health <= 0:
		dead = true
		player.set_physics_process(false)
		player.get_node("Footsteps").stream_paused = true
		show_overlay("SIGNAL LOST", "The Cretaceous won this round.\nRestart this sector and try a different route.")

func advance_stage() -> void:
	if stage == 2:
		finished = true
		player.set_physics_process(false)
		player.get_node("Footsteps").stream_paused = true
		show_overlay("BACK TO YOUR TIMELINE", "All 18 chronoshards recovered.\nExpedition time: %d:%02d\nYour journey through the Cretaceous is complete." % [int(elapsed) / 60, int(elapsed) % 60])
	else:
		stage += 1
		build_stage()

func message(text: String, seconds: float) -> void:
	toast.text = text
	toast_time = seconds
	toast.modulate.a = 1

func update_hud() -> void:
	counter.text = "CHRONOSHARDS   %02d / 06" % collected
	status.text = "SUIT INTEGRITY   " + "●  ".repeat(health) + "○  ".repeat(3 - health)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_R:
			restart()
		elif event.keycode == KEY_ESCAPE and not dead and not finished:
			paused = not paused
			get_tree().paused = paused
			if paused:
				show_overlay("EXPEDITION PAUSED", "Recover every chronoshard, avoid the dinosaurs,\nand reach the temporal rift.\nWASD move / Mouse look / Space double jump")
			else:
				overlay.hide()
				Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	if event is InputEventMouseButton and event.pressed and not paused and not dead and not finished:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func restart() -> void:
	get_tree().paused = false
	paused = false
	if finished:
		stage = 0
		elapsed = 0
	build_stage()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func show_overlay(title: String, text: String) -> void:
	resume_button.visible = paused
	overlay_title.text = title
	overlay_text.text = text
	overlay.show()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func make_label(parent: Node, text: String, size: int, color: Color = Color("dceee8")) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	parent.add_child(label)
	return label

func panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.035, 0.09, 0.09, 0.92)
	style.border_color = Color("477267")
	style.set_border_width_all(1)
	style.set_corner_radius_all(12)
	style.content_margin_left = 24
	style.content_margin_right = 24
	style.content_margin_top = 18
	style.content_margin_bottom = 18
	return style

func make_hud() -> void:
	hud = CanvasLayer.new()
	add_child(hud)
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.add_child(root)
	var top := PanelContainer.new()
	top.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	top.offset_left = 24
	top.offset_right = -24
	top.offset_top = 20
	top.offset_bottom = 120
	top.add_theme_stylebox_override("panel", panel_style())
	top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(top)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 32)
	top.add_child(row)
	var identity := VBoxContainer.new()
	identity.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(identity)
	make_label(identity, "T I M E W I L D", 28, Color("9ff4d9"))
	subtitle = make_label(identity, "", 14, Color("a3b8ae"))
	var objective := VBoxContainer.new()
	row.add_child(objective)
	counter = make_label(objective, "", 22, Color("a6fff1"))
	status = make_label(objective, "", 16, Color("ffcb89"))
	var bottom := VBoxContainer.new()
	root.add_child(bottom)
	bottom.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	bottom.offset_left = 30
	bottom.offset_right = -30
	bottom.offset_top = -132
	bottom.offset_bottom = -20
	toast = make_label(bottom, "", 18, Color("fff0ca"))
	toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	toast.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	toast.custom_minimum_size.y = 48
	progress = ProgressBar.new()
	progress.show_percentage = false
	progress.custom_minimum_size.y = 5
	progress.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bottom.add_child(progress)
	var instructions := make_label(bottom, "WASD  move     /     MOUSE  look     /     SPACE  jump + double jump     /     ESC  pause     /     R  restart sector", 15)
	instructions.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	overlay = PanelContainer.new()
	root.add_child(overlay)
	overlay.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	overlay.offset_left = -320
	overlay.offset_right = 320
	overlay.offset_top = -160
	overlay.offset_bottom = 160
	overlay.add_theme_stylebox_override("panel", panel_style())
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 18)
	overlay.add_child(column)
	overlay_title = make_label(column, "", 28, Color("9ff4d9"))
	overlay_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	overlay_text = make_label(column, "", 18)
	overlay_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var button := Button.new()
	button.text = "RESTART EXPEDITION / R"
	button.custom_minimum_size.y = 46
	button.pressed.connect(restart)
	column.add_child(button)
	resume_button = Button.new()
	resume_button.text = "RESUME / ESC"
	resume_button.pressed.connect(func():
		if paused:
			paused = false
			get_tree().paused = false
			overlay.hide()
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED)
	column.add_child(resume_button)

