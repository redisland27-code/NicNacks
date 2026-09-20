extends TextureRect
## Drag source: palette item data is passed into the grid with a color name and block shape metadata.

var block_color: String = ""

func _get_drag_data(_at_position: Vector2) -> Variant:
    if texture == null:
        return null
    var preview := TextureRect.new()
    preview.texture = texture
    preview.custom_minimum_size = Vector2(72.0, 72.0)
    preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    set_drag_preview(preview)
    return {"block_color": block_color}

func _ready() -> void:
    mouse_filter = Control.MOUSE_FILTER_STOP
    expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    if block_color == "":
        name = name.strip_edges()

func set_block_color(color_name: String) -> void:
    block_color = color_name

func get_block_color() -> String:
    return block_color

func _notification(what: int) -> void:
    if what == NOTIFICATION_PREDELETE:
        pass
