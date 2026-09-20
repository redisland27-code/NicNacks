extends Panel
## First-playable grid. Handles palette drops, legal placement, rotation, undo, and marble collection.

var _placed_piece_script: Script
var _pieces: Array = []
var _piece_map: Dictionary = {}
var _cell_to_piece: Dictionary = {}
var _selected_piece: Node = null
var _undo_stack: Array = []
var _score: int = 0
var _track_progress: int = 0
var _track_length: int = 20
var _marble_cells: Dictionary = {}
var _marble_nodes: Dictionary = {}
var _start_piece: Node = null

const STARTING_COLOR := "Grey"

func _ready() -> void:
    mouse_filter = Control.MOUSE_FILTER_STOP
    clip_contents = true
    _placed_piece_script = load("res://scripts/placed_block.gd") as Script
    var px := GameManager.get_grid_pixel_size()
    size = px
    custom_minimum_size = px
    set_process_input(true)
    initialize_board()

func initialize_board() -> void:
    _pieces.clear()
    _piece_map.clear()
    _cell_to_piece.clear()
    _marble_cells.clear()
    _marble_nodes.clear()
    _selected_piece = null
    _undo_stack.clear()
    _score = 0
    _track_progress = 0
    _track_length = 20

    var start_anchor := Vector2i(0, GameManager.grid_height / 2)
    _spawn_start_block(start_anchor)
    _spawn_marbles()
    queue_redraw()

func _draw() -> void:
    var sz := GameManager.get_grid_pixel_size()
    var cs := GameManager.cell_size
    var line := Color(0.25, 0.28, 0.32, 0.9)
    for i in range(GameManager.grid_width + 1):
        var x := float(i) * cs
        draw_line(Vector2(x, 0.0), Vector2(x, sz.y), line, 1.0)
    for j in range(GameManager.grid_height + 1):
        var y := float(j) * cs
        draw_line(Vector2(0.0, y), Vector2(sz.x, y), line, 1.0)

func _can_drop_data(at_position: Vector2, data: Variant) -> bool:
    if data is Dictionary and data.has("block_color"):
        return GameManager.is_local_inside_grid(at_position)
    return false

func _drop_data(at_position: Vector2, data: Variant) -> void:
    if data is not Dictionary:
        return
    var color_name: String = data.get("block_color", "")
    if color_name == "":
        return
    if not GameManager.BLOCK_DEFINITIONS.has(color_name):
        return

    var cell := GameManager.local_to_grid_cell(at_position)
    if _place_piece(color_name, cell, 0):
        pass

func _place_piece(color_name: String, anchor_cell: Vector2i, rotation_steps: int) -> bool:
    var cells := _get_rotated_cells_for_color(color_name, rotation_steps)
    if cells.is_empty():
        return false

    var world_cells: Array[Vector2i] = []
    for offset in cells:
        var cell := anchor_cell + offset
        if not GameManager.is_valid_tile_position(cell):
            return false
        if _cell_to_piece.has(cell):
            return false
        world_cells.append(cell)

    if not _is_legal_placement(world_cells):
        return false

    var piece := TextureRect.new()
    piece.set_script(_placed_piece_script)
    piece.texture = GameManager.get_block_texture_for_color(color_name)
    piece.custom_minimum_size = Vector2(GameManager.cell_size, GameManager.cell_size)
    piece.size = Vector2(GameManager.cell_size, GameManager.cell_size)
    piece.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    piece.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    piece.mouse_filter = Control.MOUSE_FILTER_STOP
    piece.position = GameManager.cell_to_local(anchor_cell)
    piece.name = "%s_piece_%d" % [color_name, _pieces.size()]

    if piece.has_method("setup_piece"):
        piece.setup_piece(color_name, world_cells, anchor_cell, self)
    add_child(piece)

    var piece_ref: Dictionary = {
        "color": color_name,
        "anchor": anchor_cell,
        "rotation": rotation_steps,
        "cells": world_cells,
        "node": piece,
        "id": _pieces.size(),
    }

    _pieces.append(piece_ref)
    _piece_map[piece] = piece_ref
    for cell in world_cells:
        _cell_to_piece[cell] = piece_ref

    _selected_piece = piece
    _undo_stack.append({
        "kind": "place",
        "piece": piece_ref,
        "removed_marbles": [],
        "marble_colors": {},
    })

    _destroy_marbles_if_covered(world_cells)
    _evaluate_collection()
    _advance_track_if_needed()
    queue_redraw()
    return true

func _spawn_start_block(anchor: Vector2i) -> void:
    var color_name := STARTING_COLOR
    var cells := [Vector2i(0, 0), Vector2i(0, 1)]
    var piece := TextureRect.new()
    piece.set_script(_placed_piece_script)
    piece.texture = GameManager.get_block_texture_for_color(color_name)
    piece.custom_minimum_size = Vector2(GameManager.cell_size, GameManager.cell_size)
    piece.size = Vector2(GameManager.cell_size, GameManager.cell_size)
    piece.position = GameManager.cell_to_local(anchor)
    piece.mouse_filter = Control.MOUSE_FILTER_STOP
    add_child(piece)

    var world_cells: Array[Vector2i] = []
    for offset in cells:
        var cell := anchor + offset
        world_cells.append(cell)
        _cell_to_piece[cell] = {"color": color_name, "cells": world_cells, "anchor": anchor, "node": piece}

    _start_piece = piece
    _pieces.append({"color": color_name, "anchor": anchor, "cells": world_cells, "node": piece, "id": _pieces.size()})
    _selected_piece = piece

func _spawn_marbles() -> void:
    _marble_cells.clear()
    _marble_nodes.clear()
    var attempts := 0
    while _marble_cells.size() < 10 and attempts < 240:
        attempts += 1
        var x := randi_range(1, GameManager.grid_width - 2)
        var y := randi_range(1, GameManager.grid_height - 2)
        var cell := Vector2i(x, y)
        if _cell_to_piece.has(cell):
            continue
        if _marble_cells.has(cell):
            continue
        var color_name := GameManager.random_marble_color()
        var tex := GameManager.get_marble_texture_for_color(color_name)
        if tex == null:
            continue
        var marble := TextureRect.new()
        marble.texture = tex
        marble.mouse_filter = Control.MOUSE_FILTER_IGNORE
        marble.custom_minimum_size = Vector2(GameManager.cell_size, GameManager.cell_size)
        marble.size = Vector2(GameManager.cell_size, GameManager.cell_size)
        marble.position = GameManager.cell_to_local(cell)
        marble.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
        marble.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
        add_child(marble)
        _marble_cells[cell] = color_name
        _marble_nodes[cell] = marble

func _destroy_marbles_if_covered(cells: Array[Vector2i]) -> void:
    for cell in cells:
        if _marble_cells.has(cell):
            var color := _marble_cells[cell]
            if _marble_nodes.has(cell):
                var marble := _marble_nodes[cell]
                if is_instance_valid(marble):
                    marble.queue_free()
            _marble_cells.erase(cell)
            _marble_nodes.erase(cell)

func _evaluate_collection() -> void:
    var collected: Array[Vector2i] = []
    for cell in _marble_cells.keys():
        if _is_cell_enclosed(cell):
            collected.append(cell)
    if collected.is_empty():
        return

    for cell in collected:
        var color := _marble_cells[cell]
        if _marble_nodes.has(cell):
            var node := _marble_nodes[cell]
            if is_instance_valid(node):
                node.queue_free()
        _marble_cells.erase(cell)
        _marble_nodes.erase(cell)
        _score += 10
        GameManager.add_inventory(color, 1)

func _is_cell_enclosed(cell: Vector2i) -> bool:
    var visited: Dictionary = {}
    var frontier: Array[Vector2i] = [cell]
    while not frontier.is_empty():
        var current := frontier.pop_back()
        if visited.has(current):
            continue
        visited[current] = true
        if current.x <= 0 or current.x >= GameManager.grid_width - 1 or current.y <= 0 or current.y >= GameManager.grid_height - 1:
            return false
        for delta in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
            var next := current + delta
            if not GameManager.is_valid_tile_position(next):
                return false
            if _cell_to_piece.has(next):
                continue
            if not visited.has(next):
                frontier.append(next)
    return true

func _is_legal_placement(cells: Array[Vector2i]) -> bool:
    if cells.is_empty():
        return false

    var has_corner_connection := false
    var touches_wall := false
    for cell in cells:
        var wall_touches := cell.y == 0 or cell.y == GameManager.grid_height - 1
        if wall_touches:
            touches_wall = true
        for dx in [-1, 1]:
            for dy in [-1, 1]:
                if abs(dx) + abs(dy) != 2:
                    continue
                var diag_cell := cell + Vector2i(dx, dy)
                if _cell_to_piece.has(diag_cell):
                    has_corner_connection = true
    if _pieces.size() <= 1 and cells.any(func(item): return item.x == 0):
        return true
    if not has_corner_connection and not touches_wall and _pieces.size() > 1:
        return false
    return true

func _get_rotated_cells_for_color(color_name: String, rotation_steps: int) -> Array[Vector2i]:
    var definition := GameManager.get_block_definition(color_name)
    if definition.is_empty():
        return [Vector2i(0, 0)]
    var base_cells: Array[Vector2i] = []
    for item in definition.get("cells", []):
        base_cells.append(item)
    if base_cells.is_empty():
        return [Vector2i(0, 0)]
    var rotated: Array[Vector2i] = []
    var pivot := Vector2i(0, 0)
    if base_cells.size() > 1:
        var min_x := 2147483647
        var min_y := 2147483647
        var max_x := -2147483648
        var max_y := -2147483648
        for cell in base_cells:
            min_x = mini(min_x, cell.x)
            min_y = mini(min_y, cell.y)
            max_x = maxi(max_x, cell.x)
            max_y = maxi(max_y, cell.y)
        pivot = Vector2i((min_x + max_x) / 2, (min_y + max_y) / 2)

    var turns := rotation_steps % 4
    var current := base_cells.duplicate()
    for i in range(turns):
        var next: Array[Vector2i] = []
        for cell in current:
            var rel := cell - pivot
            var rotated_cell := Vector2i(-rel.y, rel.x)
            next.append(rotated_cell + pivot)
        current = next
    rotated = current
    var min_x := 2147483647
    var min_y := 2147483647
    for cell in rotated:
        min_x = mini(min_x, cell.x)
        min_y = mini(min_y, cell.y)
    var normalized: Array[Vector2i] = []
    for cell in rotated:
        normalized.append(Vector2i(cell.x - min_x, cell.y - min_y))
    return normalized

func rotate_selected_piece() -> void:
    if _selected_piece == null:
        return
    var piece_data: Dictionary = _piece_map.get(_selected_piece, {})
    if piece_data.is_empty():
        return
    var color_name: String = piece_data.get("color", "")
    var anchor := piece_data.get("anchor", Vector2i(0, 0))
    var rotation_steps: int = int(piece_data.get("rotation", 0)) + 1
    var cells := _get_rotated_cells_for_color(color_name, rotation_steps)
    var world_cells: Array[Vector2i] = []
    for offset in cells:
        world_cells.append(anchor + offset)

    if _can_rotate_piece(piece_data, world_cells):
        _clear_piece_cells(piece_data)
        piece_data["rotation"] = rotation_steps
        piece_data["cells"] = world_cells
        for cell in world_cells:
            _cell_to_piece[cell] = piece_data
        piece_data["node"].position = GameManager.cell_to_local(anchor)
        queue_redraw()

func _can_rotate_piece(piece_data: Dictionary, world_cells: Array[Vector2i]) -> bool:
    var current_cells := piece_data.get("cells", [])
    for cell in world_cells:
        if not GameManager.is_valid_tile_position(cell):
            return false
    for cell in world_cells:
        if _cell_to_piece.has(cell) and not current_cells.has(cell):
            return false
    return true

func _clear_piece_cells(piece_data: Dictionary) -> void:
    for cell in piece_data.get("cells", []):
        if _cell_to_piece.has(cell) and _cell_to_piece[cell] == piece_data:
            _cell_to_piece.erase(cell)

func undo_last_move() -> void:
    if _undo_stack.is_empty():
        return
    var action: Dictionary = _undo_stack.pop_back()
    if action.get("kind", "") != "place":
        return
    var piece_data: Dictionary = action.get("piece", {})
    if piece_data.is_empty():
        return
    var node: Node = piece_data.get("node")
    if is_instance_valid(node):
        node.queue_free()

    for cell in piece_data.get("cells", []):
        if _cell_to_piece.has(cell) and _cell_to_piece[cell] == piece_data:
            _cell_to_piece.erase(cell)

    if _pieces.has(piece_data):
        _pieces.erase(piece_data)

    _selected_piece = _start_piece if _start_piece != null else null
    _evaluate_collection()
    queue_redraw()

func _advance_track_if_needed() -> void:
    var max_x := 0
    for piece in _pieces:
        if piece.get("cells", []).is_empty():
            continue
        for cell in piece["cells"]:
            max_x = maxi(max_x, cell.x)
    if max_x >= GameManager.grid_width - 3:
        _track_progress += 3
        _track_length += 3
        for piece in _pieces:
            if piece.get("node") == null:
                continue
            var node: TextureRect = piece["node"]
            var current_pos := node.position
            node.position = Vector2(current_pos.x - 3.0 * GameManager.cell_size, current_pos.y)
        for cell in _marble_cells.keys().duplicate():
            var new_cell := Vector2i(cell.x - 3, cell.y)
            if new_cell.x < 0:
                var marble_node := _marble_nodes.get(cell)
                if marble_node != null and is_instance_valid(marble_node):
                    marble_node.queue_free()
                _marble_cells.erase(cell)
                _marble_nodes.erase(cell)
                continue
            var color := _marble_cells[cell]
            _marble_cells.erase(cell)
            _marble_nodes.erase(cell)
            _marble_cells[new_cell] = color
            if _marble_nodes.has(new_cell):
                _marble_nodes.erase(new_cell)
            var marble_node := _marble_nodes.get(cell)
            if marble_node != null: 
                _marble_nodes[new_cell] = marble_node
                marble_node.position = GameManager.cell_to_local(new_cell)
        _reindex_piece_cells_after_scroll()
        queue_redraw()

func _reindex_piece_cells_after_scroll() -> void:
    var rebuilt: Dictionary = {}
    for piece in _pieces:
        var shifted_cells: Array[Vector2i] = []
        for cell in piece.get("cells", []):
            var new_cell := Vector2i(cell.x - 3, cell.y)
            shifted_cells.append(new_cell)
        piece["cells"] = shifted_cells
        piece["anchor"] = shifted_cells.front() if not shifted_cells.is_empty() else piece["anchor"]
        for cell in shifted_cells:
            rebuilt[cell] = piece
    _cell_to_piece = rebuilt

func _input(event: InputEvent) -> void:
    if event is InputEventMouseButton:
        var mb := event as InputEventMouseButton
        if mb.button_index == MOUSE_BUTTON_RIGHT and mb.pressed:
            rotate_selected_piece()

func _notification(what: int) -> void:
    if what == NOTIFICATION_PREDELETE:
        for marble in _marble_nodes.values():
            if is_instance_valid(marble):
                marble.queue_free()

func current_score() -> int:
    return _score

func track_progress() -> int:
    return _track_progress

func get_piece_count() -> int:
    return _pieces.size()

func get_available_marbles() -> Array[Vector2i]:
    return _marble_cells.keys()

func get_selected_piece() -> Node:
    return _selected_piece

func select_piece(piece: Node) -> void:
    _selected_piece = piece

func clear_selection() -> void:
    _selected_piece = null

func has_legal_move_available() -> bool:
    if _pieces.size() == 0:
        return true
    for color in GameManager.BLOCK_DEFINITIONS.keys():
        for x in range(GameManager.grid_width):
            for y in range(GameManager.grid_height):
                var anchor := Vector2i(x, y)
                var cells := _get_rotated_cells_for_color(color, 0)
                var valid := true
                for offset in cells:
                    var cell := anchor + offset
                    if not GameManager.is_valid_tile_position(cell):
                        valid = false
                        break
                    if _cell_to_piece.has(cell):
                        valid = false
                        break
                if valid:
                    return true
    return false

func set_track_length(length: int) -> void:
    _track_length = max(length, 20)

func get_track_length() -> int:
    return _track_length

func get_marbles() -> Dictionary:
    return _marble_cells

func recompute_board_state() -> void:
    _cell_to_piece.clear()
    for piece in _pieces:
        for cell in piece.get("cells", []):
            _cell_to_piece[cell] = piece
    _evaluate_collection()

func can_advance() -> bool:
    return _track_progress < _track_length

func debug_status() -> String:
    return "Score: %d | Blocks: %d | Marbles: %d | Progress: %d/%d" % [_score, _pieces.size(), _marble_cells.size(), _track_progress, _track_length]

func use_grey_fallback() -> void:
    if _place_piece("Grey", Vector2i(GameManager.grid_width - 2, GameManager.grid_height / 2), 0):
        pass

func _ready_for_gameplay() -> void:
    pass
