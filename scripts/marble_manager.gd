extends TextureRect
class_name PlacedBlock
## A placed block keeps the piece metadata for rotation and dragging on the board.

var piece_color: String = ""
var piece_cells: Array[Vector2i] = []
var anchor_cell: Vector2i = Vector2i.ZERO
var rotation_steps: int = 0
var grid_ref: Node = null
var dragging: bool = false
var press_offset: Vector2 = Vector2.ZERO

func setup_piece(color_name: String, cells: Array[Vector2i], anchor: Vector2i, grid: Node) -> void:
    piece_color = color_name
    piece_cells = cells
    anchor_cell = anchor
    grid_ref = grid
    texture = GameManager.get_block_texture_for_color(color_name)
    custom_minimum_size = Vector2(GameManager.cell_size, GameManager.cell_size)
    size = Vector2(GameManager.cell_size, GameManager.cell_size)
    position = GameManager.cell_to_local(anchor)
    mouse_filter = Control.MOUSE_FILTER_STOP

func _ready() -> void:
    mouse_filter = Control.MOUSE_FILTER_STOP
    expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED

func _gui_input(event: InputEvent) -> void:
    if event is InputEventMouseButton:
        var mb := event as InputEventMouseButton
        if mb.button_index == MOUSE_BUTTON_LEFT and mb.pressed:
            dragging = true
            press_offset = get_global_mouse_position() - global_position
            move_to_front()
            accept_event()
        elif mb.button_index == MOUSE_BUTTON_LEFT and not mb.pressed and dragging:
            dragging = false
            var target_cell := GameManager.local_to_grid_cell(global_position)
            if grid_ref != null and grid_ref.has_method("_can_move_selected_piece_to_cell"):
                if grid_ref._can_move_selected_piece_to_cell(self, target_cell):
                    grid_ref._move_selected_piece_to_cell(self, target_cell)
            accept_event()
    elif event is InputEventMouseMotion and dragging:
        global_position = get_global_mouse_position() - press_offset
        accept_event()

func rotate_clockwise() -> void:
    rotation_steps = (rotation_steps + 1) % 4
    if grid_ref != null and grid_ref.has_method("rotate_selected_piece"):
        grid_ref.rotate_selected_piece()

func set_anchor(cell: Vector2i) -> void:
    anchor_cell = cell
    position = GameManager.cell_to_local(cell)

func get_anchor() -> Vector2i:
    return anchor_cell

func get_piece_cells() -> Array[Vector2i]:
    return piece_cells

func get_piece_color() -> String:
    return piece_color

func _notification(what: int) -> void:
    if what == NOTIFICATION_PREDELETE:
        pass
