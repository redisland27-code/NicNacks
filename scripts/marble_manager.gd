extends Node
## Temporary Phase 1 Marble Manager – spawns 10 random marbles and will handle enclosure/collection.

const MARBLE_COLORS := ["Black", "Blue", "Green", "Orange", "Purple", "Red", "Yellow"]
const MARBLE_COUNT := 10

# cell → marble node
var marbles: Dictionary = {}

func _ready() -> void:
	# Wait one frame so GameManager and the grid are ready
	call_deferred("spawn_marbles")


func spawn_marbles() -> void:
	marbles.clear()
	
	var grid = _find_grid_node()
	if grid == null:
		push_error("MarbleManager: Could not find the Grid node!")
		return
	
	var attempts := 0
	while marbles.size() < MARBLE_COUNT and attempts < 200:
		attempts += 1
		var x := randi_range(1, GameManager.grid_width - 2)
		var y := randi_range(1, GameManager.grid_height - 2)
		var cell := Vector2i(x, y)
		
		if marbles.has(cell):
			continue
		
		_spawn_marble_at(cell, grid)
	
	print("Spawned %d marbles" % marbles.size())


func _spawn_marble_at(cell: Vector2i, grid: Control) -> void:
	var color: String = MARBLE_COLORS.pick_random()
	var path := "res://assets/marbles/Marble_%s.png" % color  # ← adjust this path if needed
	
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
	
	# Position on the grid
	marble.position = Vector2(cell.x * GameManager.cell_size, cell.y * GameManager.cell_size)
	
	grid.add_child(marble)
	
	marbles[cell] = {
		"node": marble,
		"color": color
	}
	
	print("Marble spawned at ", cell, " (", color, ")")


func _find_grid_node() -> Control:
	# Try common names first
	var root = get_tree().current_scene
	if root == null:
		return null
	
	var possible_names := ["Grid", "Board", "DropArea", "PlayArea", "GameGrid"]
	
	for name in possible_names:
		var node = root.find_child(name, true, false)
		if node is Panel or node is Control:
			return node
	
	# Fallback: find any Panel that has the grid script or is large
	var panels = root.find_children("*", "Panel", true, false)
	for p in panels:
		if p.get_script() != null:
			return p
	
	return null
