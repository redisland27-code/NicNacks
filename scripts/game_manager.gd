extends Node
## Autoload singleton: 20×20 grid math, palette discovery under [code]blocks_directory[/code], and snap helpers.

const DEFAULT_GRID_WIDTH: int = 20
const DEFAULT_GRID_HEIGHT: int = 20

## Pixel size of one grid cell (your block PNGs are ~154×155; 160 centers them with a little padding).
@export var cell_size: float = 160.0
## Root folder scanned recursively for [code].png[/code] textures (palette + drag source).
@export var blocks_directory: String = "res://assets/blocks/"

var grid_width: int = DEFAULT_GRID_WIDTH
var grid_height: int = DEFAULT_GRID_HEIGHT


func get_grid_pixel_size() -> Vector2:
	return Vector2(float(grid_width) * cell_size, float(grid_height) * cell_size)


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


## Recursively loads every [code].png[/code] under [member blocks_directory] for the palette.
func collect_block_textures() -> Array[Texture2D]:
	var out: Array[Texture2D] = []
	_collect_pngs_recursive(blocks_directory, out)
	return out


func _collect_pngs_recursive(dir_path: String, acc: Array[Texture2D]) -> void:
	var da := DirAccess.open(dir_path)
	if da == null:
		push_warning("GameManager: could not open directory: %s" % dir_path)
		return
	da.list_dir_begin()
	var entry := da.get_next()
	while entry != "":
		if entry != "." and entry != "..":
			var full := dir_path.path_join(entry)
			if da.current_is_dir():
				_collect_pngs_recursive(full, acc)
			elif entry.get_extension().to_lower() == "png":
				var res: Resource = load(full)
				if res is Texture2D:
					acc.append(res as Texture2D)
		entry = da.get_next()
	da.list_dir_end()
