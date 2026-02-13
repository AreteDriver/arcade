extends CanvasLayer

## Scene transition overlay. Fade to black and back.
## Autoload singleton — access via SceneTransition.

@onready var color_rect: ColorRect = ColorRect.new()


func _ready() -> void:
	layer = 100
	color_rect.color = Color(0, 0, 0, 0)
	color_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	color_rect.anchors_preset = Control.PRESET_FULL_RECT
	add_child(color_rect)


## Transition to a new scene with a fade effect
func change_scene(path: String, duration: float = 0.3) -> void:
	color_rect.mouse_filter = Control.MOUSE_FILTER_STOP

	# Fade out
	var tween := create_tween()
	tween.tween_property(color_rect, "color:a", 1.0, duration)
	await tween.finished

	# Change scene
	get_tree().change_scene_to_file(path)

	# Fade in
	var tween_in := create_tween()
	tween_in.tween_property(color_rect, "color:a", 0.0, duration)
	await tween_in.finished

	color_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
