extends Node
## Autoload singleton: block metadata, inventory, and grid helpers for the NickNacks first playable.

const DEFAULT_GRID_WIDTH: int = 12
const DEFAULT_GRID_HEIGHT: int = 12

@export var cell_size: float = 64.0
@export var blocks_directory: String = "res://Blocks/"
@export var marbles_directory: String = "res://Marbles/"

var grid_width: int = DEFAULT_GRID_WIDTH
var grid_height: int = DEFAULT_GRID_HEIGHT
var inventory: Dictionary = {
    "Red": 10,
    "Yellow": 10,
    "Blue": 10,
}

const BLOCK_DEFINITIONS: Dictionary = {
    "Grey": {
        "cells": [Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1)],
        "tier": 0,
        "color": "Grey"
    },
    "Red": {
        "cells": [Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1)],
        "tier": 1,
        "color": "Red"
    },
    "Yellow": {
        "cells": [Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0), Vector2i(1, 1)],
        "tier": 1,
        "color": "Yellow"
    },
    "Blue": {
        "cells": [Vector2i(0, 0), Vector2i(1, 0), Vector2i(1, 1), Vector2i(2, 1)],
        "tier": 1,
        "color": "Blue"
    },
    "Orange": {
        "cells": [Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1)],
        "tier": 2,
        "color": "Orange"
    },
    "Purple": {
        "cells": [Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0)],
        "tier": 2,
        "color": "Purple"
    },
    "Green": {
        "cells": [Vector2i(0, 0), Vector2i(1, 0)],
        "tier": 2,
        "color": "Green"
    },
    "Black": {
        "cells": [Vector2i(0, 0)],
        "tier": 3,
        "color": "Black"
    },
}

const MARBLE_CHANCES: Dictionary = {
    "Red": 0.15,
    "Blue": 0.15,
    "Yellow": 0.15,
    "Green": 0.08,
    "Purple": 0.08,
    "Orange": 0.08,
    "Black": 0.03,
}

func get_grid_pixel_size() -> Vector2:
    return Vector2(float(grid_width) * cell_size, float(grid_height) * cell_size)

func cell_to_local(cell: Vector2i) -> Vector2:
    return Vector2(float(cell.x) * cell_size, float(cell.y) * cell_size)

func snap_local_position_to_grid(local_pos: Vector2) -> Vector2:
    var gx := int(floor(local_pos.x / cell_size))
    var gy := int(floor(local_pos.y / cell_size))
    gx = clampi(gx, 0, grid_width - 1)
    gy = clampi(gy, 0, grid_height - 1)
    return Vector2(float(gx) * cell_size, float(gy) * cell_size)

func local_to_grid_cell(local_pos: Vector2) -> Vector2i:
    var gx := int(floor(local_pos.x / cell_size))
    var gy := int(floor(local_pos.y / cell_size))
    gx = clampi(gx, 0, grid_width - 1)
    gy = clampi(gy, 0, grid_height - 1)
    return Vector2i(gx, gy)

func is_local_inside_grid(local_pos: Vector2) -> bool:
    var sz := get_grid_pixel_size()
    return local_pos.x >= 0.0 and local_pos.y >= 0.0 and local_pos.x < sz.x and local_pos.y < sz.y

func get_block_definition(color_name: String) -> Dictionary:
    return BLOCK_DEFINITIONS.get(color_name, {})

func get_block_texture_for_color(color_name: String) -> Texture2D:
    var dir_path := blocks_directory.path_join(color_name)
    var dir := DirAccess.open(dir_path)
    if dir == null:
        return null
    dir.list_dir_begin() 
    var entry := dir.get_next()
    while entry != "":
        if entry != "." and entry != ".." and entry.get_extension().to_lower() == "png":
            var tex := load(dir_path.path_join(entry)) as Texture2D
            if tex != null:
                dir.list_dir_end()
                return tex
        entry = dir.get_next()
    dir.list_dir_end()
    return null

func collect_block_textures() -> Array[Texture2D]:
    var textures: Array[Texture2D] = []
    var colors := ["Black", "Blue", "Green", "Grey", "Orange", "Purple", "Red", "Yellow"]
    for color_name in colors:
        var tex := get_block_texture_for_color(color_name)
        if tex != null:
            textures.append(tex)
    return textures

func get_marble_texture_for_color(color_name: String) -> Texture2D:
    var path := marbles_directory.path_join("Marble_%s.png" % color_name)
    return load(path) as Texture2D

func random_marble_color() -> String:
    var weights := [
        ["Red", 0.15],
        ["Blue", 0.15],
        ["Yellow", 0.15],
        ["Green", 0.08],
        ["Purple", 0.08],
        ["Orange", 0.08],
        ["Black", 0.03],
    ]
    var roll := randf()
    var running := 0.0
    for entry in weights:
        running += float(entry[1])
        if roll <= running:
            return String(entry[0])
    return "Red"

func is_valid_tile_position(cell: Vector2i) -> bool:
    return cell.x >= 0 and cell.y >= 0 and cell.x < grid_width and cell.y < grid_height

func add_inventory(color: String, amount: int = 1) -> void:
    if not inventory.has(color):
        inventory[color] = 0
    inventory[color] += amount

func reset_inventory() -> void:
    inventory = {"Red": 10, "Yellow": 10, "Blue": 10}

func get_color_order() -> Array[String]:
    return ["Grey", "Red", "Yellow", "Blue", "Orange", "Purple", "Green", "Black"]

func formatted_inventory() -> String:
    var text := ""
    for color in get_color_order():
        text += "%s: %s\n" % [color, inventory.get(color, 0)]
    return text.trim_suffix("\n")

func get_cell_size() -> float:
    return cell_size

func set_cell_size(value: float) -> void:
    cell_size = value

func set_grid_size(width: int, height: int) -> void:
    grid_width = width
    grid_height = height

func cell_to_world(cell: Vector2i) -> Vector2:
    return Vector2(float(cell.x) * cell_size, float(cell.y) * cell_size)

func rotate_block_definition(color_name: String, turns: int) -> Array[Vector2i]:
    var cells: Array[Vector2i] = []
    var base := get_block_definition(color_name).get("cells", [Vector2i(0, 0)])
    for c in base:
        cells.append(c)
    if cells.is_empty():
        return [Vector2i(0, 0)]
    var pivot := Vector2i(0, 0)
    var min_x := 2147483647
    var min_y := 2147483647
    var max_x := -2147483648
    var max_y := -2147483648
    for c in cells:
        min_x = mini(min_x, c.x)
        min_y = mini(min_y, c.y)
        max_x = maxi(max_x, c.x)
        max_y = maxi(max_y, c.y)
    pivot = Vector2i((min_x + max_x) / 2, (min_y + max_y) / 2)
    var current := cells.duplicate()
    for i in range(turns % 4):
        var next: Array[Vector2i] = []
        for c in current:
            var rel := c - pivot
            next.append(pivot + Vector2i(-rel.y, rel.x))
        current = next
    return current

func shape_cells_for(color_name: String) -> Array[Vector2i]:
    return get_block_definition(color_name).get("cells", [Vector2i(0, 0)])

func get_inventory_value(color: String) -> int:
    return inventory.get(color, 0)
