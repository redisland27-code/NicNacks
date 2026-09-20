extends Control
## Builds the palette from [method GameManager.collect_block_textures].

const PALETTE_ITEM_SCRIPT := preload("res://scripts/palette_item.gd")

@onready var _palette_flow: HFlowContainer = $HBox/PaletteScroll/PaletteFlow


func _ready() -> void:
	for tex in GameManager.collect_block_textures():
		var item := TextureRect.new()
		item.texture = tex
		item.custom_minimum_size = Vector2(72.0, 72.0)
		item.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		item.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		item.mouse_filter = Control.MOUSE_FILTER_STOP
		item.set_script(PALETTE_ITEM_SCRIPT)
		_palette_flow.add_child(item)
