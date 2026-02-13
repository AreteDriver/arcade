extends Node

## Centralized visual feedback system.
## Autoload singleton — access via VFX.
## Uses Tweens for animations and GPUParticles2D for particle effects.


## Scale pop: 0 → 1.1 → 1.0 (satisfying placement feel)
func pop_scale(node: Node2D, duration: float = 0.3) -> void:
	node.scale = Vector2(0.3, 0.3)
	var tween := node.create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_BACK)
	tween.tween_property(node, "scale", Vector2(1.1, 1.1), duration * 0.6)
	tween.tween_property(node, "scale", Vector2.ONE, duration * 0.4).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)


## Shrink and fade out (delete animation), then queue_free
func shrink_and_free(node: Node2D, duration: float = 0.25) -> void:
	var tween := node.create_tween()
	tween.set_ease(Tween.EASE_IN)
	tween.set_trans(Tween.TRANS_BACK)
	tween.set_parallel(true)
	tween.tween_property(node, "scale", Vector2(0.1, 0.1), duration)
	tween.tween_property(node, "modulate:a", 0.0, duration)
	tween.set_parallel(false)
	tween.tween_callback(node.queue_free)


## Shake a node (random offset jitter)
func shake_node(node: Node2D, intensity: float = 4.0, duration: float = 0.3) -> void:
	var original_pos: Vector2 = node.position
	var tween := node.create_tween()
	var steps: int = int(duration / 0.03)
	for i in range(steps):
		var offset := Vector2(randf_range(-intensity, intensity), randf_range(-intensity, intensity))
		var decay: float = 1.0 - float(i) / float(steps)
		tween.tween_property(node, "position", original_pos + offset * decay, 0.03)
	tween.tween_property(node, "position", original_pos, 0.03)


## Flash modulate color then return to white
func flash_color(node: Node2D, color: Color, duration: float = 0.2) -> void:
	var tween := node.create_tween()
	tween.tween_property(node, "modulate", color, duration * 0.3)
	tween.tween_property(node, "modulate", Color.WHITE, duration * 0.7)


## Pulse modulate (throb effect for warnings)
func pulse_modulate(node: Node2D, color: Color, count: int = 3, duration: float = 0.6) -> void:
	var tween := node.create_tween()
	tween.set_loops(count)
	tween.tween_property(node, "modulate", color, duration / 2.0)
	tween.tween_property(node, "modulate", Color.WHITE, duration / 2.0)


## Glow effect: temporarily brighten a node
func glow(node: Node2D, color: Color = Color(1.3, 1.3, 1.5), duration: float = 0.4) -> void:
	var tween := node.create_tween()
	tween.tween_property(node, "modulate", color, duration * 0.3)
	tween.tween_property(node, "modulate", Color.WHITE, duration * 0.7).set_ease(Tween.EASE_OUT)


## Connection flash: brief glow at a port position
func connection_flash(port: Node2D) -> void:
	var flash := _create_flash_circle(port.global_position, Port.TYPE_COLORS.get(port.port_type, Color.WHITE) if port is Port else Color.WHITE)
	_add_effect(flash, port)


## Spawn spark particles at a world position
func spawn_sparks(world_pos: Vector2, color: Color = Color(1.0, 0.8, 0.2), count: int = 12, parent: Node = null) -> void:
	var particles := GPUParticles2D.new()
	particles.amount = count
	particles.one_shot = true
	particles.lifetime = 0.4
	particles.explosiveness = 0.9
	particles.global_position = world_pos

	var mat := ParticleProcessMaterial.new()
	mat.direction = Vector3(0, -1, 0)
	mat.spread = 180.0
	mat.initial_velocity_min = 80.0
	mat.initial_velocity_max = 180.0
	mat.gravity = Vector3(0, 300, 0)
	mat.damping_min = 2.0
	mat.damping_max = 4.0
	mat.scale_min = 1.5
	mat.scale_max = 3.0
	mat.color = color

	particles.process_material = mat
	particles.emitting = true
	particles.finished.connect(particles.queue_free)

	if parent:
		parent.add_child(particles)
	else:
		_add_to_scene(particles)


## Spawn smoke puff
func spawn_smoke(world_pos: Vector2, parent: Node = null) -> void:
	var particles := GPUParticles2D.new()
	particles.amount = 8
	particles.one_shot = true
	particles.lifetime = 0.6
	particles.explosiveness = 0.8
	particles.global_position = world_pos

	var mat := ParticleProcessMaterial.new()
	mat.direction = Vector3(0, -1, 0)
	mat.spread = 60.0
	mat.initial_velocity_min = 20.0
	mat.initial_velocity_max = 50.0
	mat.gravity = Vector3(0, -40, 0)
	mat.damping_min = 3.0
	mat.damping_max = 5.0
	mat.scale_min = 3.0
	mat.scale_max = 6.0
	mat.color = Color(0.5, 0.5, 0.55, 0.6)

	particles.process_material = mat
	particles.emitting = true
	particles.finished.connect(particles.queue_free)

	if parent:
		parent.add_child(particles)
	else:
		_add_to_scene(particles)


## Celebration burst (rainbow sparks)
func celebrate(world_pos: Vector2, parent: Node = null) -> void:
	var particles := GPUParticles2D.new()
	particles.amount = 24
	particles.one_shot = true
	particles.lifetime = 0.8
	particles.explosiveness = 0.95
	particles.global_position = world_pos

	var mat := ParticleProcessMaterial.new()
	mat.direction = Vector3(0, -1, 0)
	mat.spread = 180.0
	mat.initial_velocity_min = 120.0
	mat.initial_velocity_max = 250.0
	mat.gravity = Vector3(0, 200, 0)
	mat.damping_min = 1.0
	mat.damping_max = 3.0
	mat.scale_min = 2.0
	mat.scale_max = 4.0

	# Rainbow color ramp
	var gradient := Gradient.new()
	gradient.set_color(0, Color(1, 0.2, 0.2))
	gradient.add_point(0.2, Color(1, 0.8, 0.1))
	gradient.add_point(0.4, Color(0.2, 1, 0.3))
	gradient.add_point(0.6, Color(0.2, 0.6, 1))
	gradient.add_point(0.8, Color(0.8, 0.3, 1))
	gradient.set_color(1, Color(1, 0.5, 0.8))

	var color_ramp := GradientTexture1D.new()
	color_ramp.gradient = gradient
	mat.color_ramp = color_ramp

	particles.process_material = mat
	particles.emitting = true
	particles.finished.connect(particles.queue_free)

	if parent:
		parent.add_child(particles)
	else:
		_add_to_scene(particles)


## Warning pulse (red throb)
func warning(node: Node2D) -> void:
	pulse_modulate(node, Color(1.4, 0.5, 0.5), 3, 0.4)


## Break effect: sparks + smoke + shake
func break_effect(node: Node2D) -> void:
	spawn_sparks(node.global_position, Color(1, 0.6, 0.1), 16)
	spawn_smoke(node.global_position)
	shake_node(node, 6.0, 0.4)


## Screen shake via camera
func screen_shake(camera: Camera2D, intensity: float = 5.0, duration: float = 0.3) -> void:
	var original_offset: Vector2 = camera.offset
	var tween := camera.create_tween()
	var steps: int = int(duration / 0.03)
	for i in range(steps):
		var offset := Vector2(randf_range(-intensity, intensity), randf_range(-intensity, intensity))
		var decay: float = 1.0 - float(i) / float(steps)
		tween.tween_property(camera, "offset", original_offset + offset * decay, 0.03)
	tween.tween_property(camera, "offset", original_offset, 0.03)


## Create a brief expanding circle flash
func _create_flash_circle(world_pos: Vector2, color: Color) -> Node2D:
	var flash := FlashCircle.new()
	flash.global_position = world_pos
	flash.color = color
	return flash


func _add_effect(effect: Node2D, ref_node: Node) -> void:
	var parent: Node = ref_node.get_parent()
	if parent:
		parent.add_child(effect)
	else:
		_add_to_scene(effect)


func _add_to_scene(node: Node) -> void:
	get_tree().current_scene.add_child(node)


## Inner class: expanding circle that fades out
class FlashCircle extends Node2D:
	var color: Color = Color.WHITE
	var radius: float = 4.0
	var max_radius: float = 24.0
	var lifetime: float = 0.25
	var _time: float = 0.0

	func _ready() -> void:
		z_index = 10

	func _process(delta: float) -> void:
		_time += delta
		var t: float = _time / lifetime
		if t >= 1.0:
			queue_free()
			return
		radius = lerpf(4.0, max_radius, t)
		color.a = 1.0 - t
		queue_redraw()

	func _draw() -> void:
		draw_arc(Vector2.ZERO, radius, 0, TAU, 24, color, 2.5)
		draw_circle(Vector2.ZERO, radius * 0.3, Color(color.r, color.g, color.b, color.a * 0.4))
