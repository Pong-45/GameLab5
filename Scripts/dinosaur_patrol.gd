extends Node3D
const Art = preload("res://Scripts/prehistoric_assets.gd")
var route_start := Vector3.ZERO
var route_end := Vector3.ZERO
var pace := 2.0
var phase := 0.0
var dangerous := true
var world: Node
var direction := 1.0
var progress := 0.0

func _physics_process(delta: float) -> void:
	if world.finished or world.dead:
		return
	var distance := route_start.distance_to(route_end)
	progress += delta * pace * direction / maxf(distance, 0.1)
	if progress >= 1.0:
		progress = 1.0
		direction = -1.0
	elif progress <= 0.0:
		progress = 0.0
		direction = 1.0
	position = route_start.lerp(route_end, progress)
	var heading := (route_end - route_start) * direction
	rotation.y = lerp_angle(rotation.y, atan2(heading.x, heading.z), delta * 5.0)
	if dangerous and world.player.global_position.distance_to(global_position + Vector3.UP * 0.5) < 1.65:
		world.hurt("A dinosaur caught you! Watch its patrol route.")
