class_name Port
extends Marker2D

## A typed connection point on a MachineComponent.
## Ports connect to other ports of matching type via wires.

enum PortType { ENERGY, FLOW, SIGNAL }
enum Direction { INPUT, OUTPUT }

## The type of data this port carries
@export var port_type: PortType = PortType.ENERGY
## Whether this is an input or output port
@export var direction: Direction = Direction.INPUT
## Display name for this port
@export var port_name: String = ""

## The port this is connected to (null if unconnected)
var connected_to: Port = null
## The component that owns this port
var owner_component: Node2D = null

## Visual state
var hover: bool = false
var port_radius: float = 8.0

## Color mapping for port types
const TYPE_COLORS: Dictionary = {
	PortType.ENERGY: Color(1.0, 0.8, 0.0),   # Yellow
	PortType.FLOW: Color(0.0, 0.7, 1.0),      # Cyan-blue
	PortType.SIGNAL: Color(0.0, 1.0, 0.4),    # Green
}

signal connection_changed(connected_port: Port)


func _ready() -> void:
	queue_redraw()


func _draw() -> void:
	var color: Color = TYPE_COLORS.get(port_type, Color.WHITE)
	if hover:
		color = color.lightened(0.3)

	# Outer ring
	draw_circle(Vector2.ZERO, port_radius, color)
	# Inner fill — hollow when disconnected, solid when connected
	if connected_to == null:
		draw_circle(Vector2.ZERO, port_radius * 0.5, Color(0.1, 0.1, 0.15))
	else:
		draw_circle(Vector2.ZERO, port_radius * 0.6, color.lightened(0.2))

	# Direction indicator — small arrow
	if direction == Direction.OUTPUT:
		var arrow_color: Color = color.darkened(0.2)
		draw_line(Vector2(port_radius + 2, 0), Vector2(port_radius + 8, 0), arrow_color, 2.0)
		draw_line(Vector2(port_radius + 6, -3), Vector2(port_radius + 8, 0), arrow_color, 2.0)
		draw_line(Vector2(port_radius + 6, 3), Vector2(port_radius + 8, 0), arrow_color, 2.0)


func get_color() -> Color:
	return TYPE_COLORS.get(port_type, Color.WHITE)


## Check if this port can connect to another
func can_connect_to(other: Port) -> bool:
	if other == null or other == self:
		return false
	if other.port_type != port_type:
		return false
	if other.direction == direction:
		return false
	if connected_to != null or other.connected_to != null:
		return false
	if other.owner_component == owner_component:
		return false
	return true


## Establish connection to another port
func connect_to_port(other: Port) -> void:
	if not can_connect_to(other):
		return
	connected_to = other
	other.connected_to = self
	connection_changed.emit(other)
	other.connection_changed.emit(self)
	queue_redraw()
	other.queue_redraw()


## Break connection
func disconnect_port() -> void:
	if connected_to == null:
		return
	var other: Port = connected_to
	connected_to = null
	other.connected_to = null
	connection_changed.emit(null)
	other.connection_changed.emit(null)
	queue_redraw()
	other.queue_redraw()


func set_hover(value: bool) -> void:
	if hover != value:
		hover = value
		queue_redraw()
