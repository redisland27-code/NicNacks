extends Panel
## 20×20 drop target and grid lines. Accepts drags from [PaletteItem] and spawns [PlacedBlock] children.

var _placed_block_script: Script


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	clip_contents = true
	_placed_block_script = load("res://scripts/placed_block.gd") as Script
	var px := GameManager.get_grid_pixel_size()
	custom_minimum_size = px
	size_flags_vertical = Control.SIZE_SHRINK_CENTER


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
	if data is Dictionary and data.get("block_texture") is Texture2D:
		return GameManager.is_local_inside_grid(at_position)
	return false


func _drop_data(at_position: Vector2, data: Variant) -> void:
	var tex: Texture2D = data["block_texture"] as Texture2D
	var block := TextureRect.new()
	block.texture = tex
	block.set_script(_placed_block_script)
	var cell := GameManager.cell_size
	block.custom_minimum_size = Vector2(cell, cell)
	block.size = Vector2(cell, cell)
	add_child(block)
	block.position = GameManager.snap_local_position_to_grid(at_position)
