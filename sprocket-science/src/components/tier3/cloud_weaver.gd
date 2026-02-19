class_name CloudWeaver
extends MachineComponent

## Particle system sculptor. Shapes flow into cloud-like formations.
## Input: Flow + Energy. Output: Flow. Parameters: density, turbulence.

const WEAVER_SIZE: float = 54.0
const WEAVER_COLOR := Color(0.4, 0.45, 0.6)
const CLOUD_COLOR := Color(0.8, 0.85, 0.95)

var _flow_in: float = 0.0
var _energy_in: float = 0.0
var _cloud_time: float = 0.0
var _puffs: Array[Dictionary] = []


func _setup_ports() -> void:
	add_port("flow_in", Port.PortType.FLOW, Port.Direction.INPUT, Vector2(-WEAVER_SIZE / 2.0 - 12, -8))
	add_port("energy_in", Port.PortType.ENERGY, Port.Direction.INPUT, Vector2(-WEAVER_SIZE / 2.0 - 12, 8))
	add_port("flow_out", Port.PortType.FLOW, Port.Direction.OUTPUT, Vector2(WEAVER_SIZE / 2.0 + 12, 0))


func _setup_parameters() -> void:
	register_parameter("density", "Density", 50.0, 10.0, 100.0, 1.0)
	register_parameter("turbulence", "Turbulence", 30.0, 0.0, 100.0, 1.0)


func _on_input_received(port: Port, data: Variant) -> void:
	if data is Dictionary:
		if port.port_name == "flow_in":
			_flow_in = data.get("flow_rate", 0.0)
		elif port.port_name == "energy_in":
			_energy_in = data.get("energy", 0.0)


func _process_component(delta: float) -> void:
	var density: float = get_parameter("density") / 100.0
	var turbulence: float = get_parameter("turbulence") / 100.0
	_cloud_time += delta

	# Spawn cloud puffs
	if current_state == State.ACTIVE and _flow_in > 0.05:
		if fmod(_cloud_time, 0.2 + (1.0 - density) * 0.5) < delta:
			_puffs.append({
				"x": randf_range(-WEAVER_SIZE * 0.3, WEAVER_SIZE * 0.3),
				"y": randf_range(-WEAVER_SIZE * 0.3, WEAVER_SIZE * 0.3),
				"r": randf_range(6.0, 12.0) * density,
				"life": 0.0,
				"drift_x": randf_range(-1.0, 1.0) * turbulence,
				"drift_y": randf_range(-0.5, -1.5),
			})

	# Update puffs
	var alive: Array[Dictionary] = []
	for puff in _puffs:
		puff["life"] += delta
		puff["x"] += puff["drift_x"] * delta * 20.0
		puff["y"] += puff["drift_y"] * delta * 15.0
		puff["r"] += delta * 3.0
		if puff["life"] < 2.0:
			alive.append(puff)
	_puffs = alive

	# Output sculpted flow
	var power: float = clampf(_energy_in + 0.2, 0.0, 1.0)
	var output: float = _flow_in * density * power
	send_output("flow_out", {"flow_rate": clampf(output, 0.0, 2.0)})
	_flow_in = 0.0
	_energy_in = 0.0
	queue_redraw()


func reset_component() -> void:
	super.reset_component()
	_flow_in = 0.0
	_energy_in = 0.0
	_cloud_time = 0.0
	_puffs.clear()
	queue_redraw()


func _draw_component() -> void:
	var half := WEAVER_SIZE / 2.0

	# Housing
	draw_rect(Rect2(-half, -half, WEAVER_SIZE, WEAVER_SIZE), WEAVER_COLOR.darkened(0.4), true)
	draw_rect(Rect2(-half, -half, WEAVER_SIZE, WEAVER_SIZE), WEAVER_COLOR, false, 2.0)

	# Loom pattern inside
	for i in range(4):
		var y: float = lerpf(-half + 8, half - 8, float(i) / 3.0)
		draw_line(Vector2(-half + 6, y), Vector2(half - 6, y), WEAVER_COLOR.lightened(0.15), 1.0)
	for i in range(4):
		var x: float = lerpf(-half + 8, half - 8, float(i) / 3.0)
		draw_line(Vector2(x, -half + 6), Vector2(x, half - 6), WEAVER_COLOR.lightened(0.15), 1.0)

	# Cloud puffs
	for puff in _puffs:
		var alpha: float = (1.0 - puff["life"] / 2.0) * 0.5
		var pc: Color = Color(CLOUD_COLOR.r, CLOUD_COLOR.g, CLOUD_COLOR.b, alpha)
		draw_circle(Vector2(puff["x"], puff["y"]), puff["r"], pc)

	draw_string(ThemeDB.fallback_font, Vector2(-28, -half - 8),
		"Cloud Weaver", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(0.6, 0.6, 0.7))


func _get_bounds() -> Rect2:
	var half := WEAVER_SIZE / 2.0
	return Rect2(-half - 12, -half - 20, WEAVER_SIZE + 24, WEAVER_SIZE + 40)


func _get_component_type() -> String:
	return "cloud_weaver"
