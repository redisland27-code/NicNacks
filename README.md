extends Node
## Marble spawn manager for the first-playable board.

const MARBLE_COLORS := ["Black", "Blue", "Green", "Orange", "Purple", "Red", "Yellow"]
const MARBLE_COUNT := 10

var marbles: Dictionary = {}

func _ready() -> void:
    call_deferred("spawn_marbles")

func spawn_marbles() -> void:
    marbles.clear()
    var grid = _find_grid_node()
    if grid == null:
        push_error("MarbleManager: Could not find the Grid node!")
        return
    var attempts := 0
    while marbles.size() < MARBLE_COUNT and attempts < 240:
        attempts += 1
        var x := randi_range(1, GameManager.grid_width - 2)
        var y := randi_range(1, GameManager.grid_height - 2)
        var cell := Vector2i(x, y)
        if marbles.has(cell):
            continue
        _spawn_marble_at(cell, grid)

func _spawn_marble_at(cell: Vector2i, grid: Control) -> void:
    var color: String = MARBLE_COLORS.pick_random()
    var path := "res://Marbles/Marble_%s.png" % color
    var tex := load(path) as Texture2D
    if tex == null:
        push_warning("Could not load marble: " + path)
        return

    var marble := TextureRect.new()
    marble.texture = tex
    marble.custom_minimum_size = Vector2(GameManager.cell_size, GameManager.cell_size)
    marble.size = Vector2(GameManager.cell_size, GameManager.cell_size)
    marble.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    marble.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    marble.mouse_filter = Control.MOUSE_FILTER_IGNORE
    marble.position = Vector2(cell.x * GameManager.cell_size, cell.y * GameManager.cell_size)
    grid.add_child(marble)
    marbles[cell] = {"node": marble, "color": color}

func _find_grid_node() -> Control:
    var root = get_tree().current_scene
    if root == null:
        return null
    var candidates := ["GridPlayfield", "Grid", "Board", "DropArea", "PlayArea", "GameGrid"]
    for name in candidates:
        var node = root.find_child(name, true, false)
        if node is Control:
            return node
    return null

func clear_marbles() -> void:
    for marble_data in marbles.values():
        if marble_data.has("node"):
            var node := marble_data["node"] as Node
            if is_instance_valid(node):
                node.queue_free()
    marbles.clear()
