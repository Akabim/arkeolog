extends Resource
class_name RockData

@export var texture: Texture2D
@export var max_clicks: int = 3

## Jika true, gambar batu di-render se-kanvas penuh. 
## Jika false, gambar batu akan di-render di posisi custom_position.
@export var full_canvas: bool = true
@export var custom_position: Vector2 = Vector2.ZERO
