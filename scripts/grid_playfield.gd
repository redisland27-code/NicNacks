extends Control
## Builds the active palette and exposes a minimal first-playable HUD.

const PALETTE_ITEM_SCRIPT := preload("res://scripts/palette_item.gd")

@onready var _palette_flow: HFlowContainer = $HBox/PaletteScroll/PaletteFlow

var _undo_button: Button
var _rotate_button: Button

func _ready() -> void:
    _build_palette()
    _add_action_buttons()
    var grid := $HBox/GridPlayfield as Panel
    if grid != null and grid.has_method("initialize_board"):
        grid.initialize_board()

func _build_palette() -> void:
    for child in _palette_flow.get_children():
        child.queue_free()

    var colors := ["Grey", "Red", "Yellow", "Blue", "Orange", "Purple", "Green", "Black"]
    for color_name in colors:
        var tex := GameManager.get_block_texture_for_color(color_name)
        if tex == null:
            continue
        var item := TextureRect.new()
        item.texture = tex
        item.custom_minimum_size = Vector2(80.0, 80.0)
        item.size = Vector2(80.0, 80.0)
        item.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
        item.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
        item.mouse_filter = Control.MOUSE_FILTER_STOP
        item.set_script(PALETTE_ITEM_SCRIPT)
        item.name = "Palette_%s" % color_name
        item.block_color = color_name
        _palette_flow.add_child(item)

func _add_action_buttons() -> void:
    var parent := $HBox as HBoxContainer
    if parent == null:
        return

    _undo_button = Button.new()
    _undo_button.text = "Undo"
    _undo_button.custom_minimum_size = Vector2(104.0, 42.0)
    _undo_button.pressed.connect(_on_undo_pressed)
    parent.add_child(_undo_button)

    _rotate_button = Button.new()
    _rotate_button.text = "Rotate"
    _rotate_button.custom_minimum_size = Vector2(104.0, 42.0)
    _rotate_button.pressed.connect(_on_rotate_pressed)
    parent.add_child(_rotate_button)

func _on_undo_pressed() -> void:
    var grid := $HBox/GridPlayfield as Panel
    if grid != null and grid.has_method("undo_last_move"):
        grid.undo_last_move()

func _on_rotate_pressed() -> void:
    var grid := $HBox/GridPlayfield as Panel
    if grid != null and grid.has_method("rotate_selected_piece"):
        grid.rotate_selected_piece()

func _process(_delta: float) -> void:
    if Input.is_action_just_pressed("ui_undo"):
        _on_undo_pressed()
    if Input.is_action_just_pressed("ui_rotate"):
        _on_rotate_pressed()

func _input(event: InputEvent) -> void:
    if event is InputEventKey:
        var key_event := event as InputEventKey
        if key_event.pressed:
            if key_event.keycode == KEY_Z and Input.is_key_pressed(KEY_CTRL):
                _on_undo_pressed()
            if key_event.keycode == KEY_R:
                _on_rotate_pressed()

func get_undo_button() -> Button:
    return _undo_button

func get_rotate_button() -> Button:
    return _rotate_button

func _notification(what: int) -> void:
    if what == NOTIFICATION_PREDELETE:
        if _undo_button != null:
            _undo_button.queue_free()
        if _rotate_button != null:
            _rotate_button.queue_free()

func _draw() -> void:
    pass
