class_name ComponentGraph
extends RefCounted

## Directed graph managing component connections.
## Handles topological sort for evaluation order and serialization.

## All components in the graph: {node_name: MachineComponent}
var _components: Dictionary = {}

## Adjacency list: {source_name: [{target_name, source_port, target_port}]}
var _connections: Dictionary = {}


## Add a component to the graph
func add_component(component: MachineComponent) -> void:
	_components[component.name] = component
	if component.name not in _connections:
		_connections[component.name] = []


## Remove a component and all its connections
func remove_component(component: MachineComponent) -> void:
	var comp_name: String = component.name

	# Disconnect all ports
	for port in component.get_all_ports():
		if port.connected_to != null:
			port.disconnect_port()

	# Remove from adjacency list
	_connections.erase(comp_name)

	# Remove connections pointing to this component
	for source_name in _connections:
		var filtered: Array = _connections[source_name].filter(
			func(conn: Dictionary) -> bool: return conn["target_name"] != comp_name
		)
		_connections[source_name] = filtered

	_components.erase(comp_name)


## Connect two ports and record in the graph
func connect_ports(source: Port, target: Port) -> bool:
	if not source.can_connect_to(target):
		return false

	source.connect_to_port(target)

	var source_name: String = source.owner_component.name
	var target_name: String = target.owner_component.name

	if source_name not in _connections:
		_connections[source_name] = []

	_connections[source_name].append({
		"target_name": target_name,
		"source_port": source.port_name,
		"target_port": target.port_name,
	})
	return true


## Disconnect two ports
func disconnect_ports(source: Port) -> void:
	if source.connected_to == null:
		return

	var source_name: String = source.owner_component.name
	var target_name: String = source.connected_to.owner_component.name
	var target_port_name: String = source.connected_to.port_name

	source.disconnect_port()

	if source_name in _connections:
		_connections[source_name] = _connections[source_name].filter(
			func(conn: Dictionary) -> bool:
				return not (conn["target_name"] == target_name and
					conn["source_port"] == source.port_name and
					conn["target_port"] == target_port_name)
		)


## Get topological evaluation order using Kahn's algorithm
func get_evaluation_order() -> Array[MachineComponent]:
	var in_degree: Dictionary = {}
	for comp_name in _components:
		in_degree[comp_name] = 0

	for source_name in _connections:
		for conn in _connections[source_name]:
			var target: String = conn["target_name"]
			if target in in_degree:
				in_degree[target] += 1

	# Start with zero in-degree nodes
	var queue: Array[String] = []
	for comp_name in in_degree:
		if in_degree[comp_name] == 0:
			queue.append(comp_name)

	var order: Array[MachineComponent] = []
	while queue.size() > 0:
		var current: String = queue.pop_front()
		if current in _components:
			order.append(_components[current])

		if current in _connections:
			for conn in _connections[current]:
				var target: String = conn["target_name"]
				if target in in_degree:
					in_degree[target] -= 1
					if in_degree[target] == 0:
						queue.append(target)

	# If cycle detected, add remaining components in arbitrary order
	if order.size() < _components.size():
		for comp_name in _components:
			if _components[comp_name] not in order:
				order.append(_components[comp_name])

	return order


## Get all components
func get_components() -> Array[MachineComponent]:
	var result: Array[MachineComponent] = []
	for comp_name in _components:
		result.append(_components[comp_name])
	return result


## Get component by name
func get_component(comp_name: String) -> MachineComponent:
	return _components.get(comp_name)


## Get number of components
func get_count() -> int:
	return _components.size()


## Clear all components and connections
func clear() -> void:
	for comp_name in _components:
		var comp: MachineComponent = _components[comp_name]
		for port in comp.get_all_ports():
			if port.connected_to != null:
				port.disconnect_port()
	_components.clear()
	_connections.clear()


## Serialize the entire graph to a Dictionary
func serialize() -> Dictionary:
	var components_data: Array[Dictionary] = []
	for comp_name in _components:
		components_data.append(_components[comp_name].serialize())
	return {"components": components_data}


## Check if graph has any components
func is_empty() -> bool:
	return _components.size() == 0
