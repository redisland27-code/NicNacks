extends TextureRect
## Drag source: sprites from the palette become [code]{"block_texture": Texture2D}[/code] drag payload.

func _get_drag_data(_at_position: Vector2) -> Variant:
	if texture == null:
		return null
	var preview := TextureRect.new()
	preview.texture = texture
	preview.custom_minimum_size = Vector2(72.0, 72.0)
	preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	set_drag_preview(preview)
	return {"block_texture": texture}
