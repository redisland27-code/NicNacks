extends TextureRect
class_name PlacedBlock
## One block on the grid: drag with LMB, release to snap to the nearest cell inside the 20×20 area.

var _dragging: bool = false
var _press_offset: Vector2


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT:
			if mb.pressed:
				_dragging = true
				_press_offset = get_global_mouse_position() - global_position
				move_to_front()
				accept_event()
			elif _dragging:
				_dragging = false
				var parent_ctrl := get_parent() as Control
				if parent_ctrl:
					var local_tl := global_position - parent_ctrl.global_position
					position = GameManager.snap_local_position_to_grid(local_tl)
				accept_event()
	elif event is InputEventMouseMotion and _dragging:
		global_position = get_global_mouse_position() - _press_offset
		accept_event()
