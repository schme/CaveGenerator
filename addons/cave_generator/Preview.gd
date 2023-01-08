tool
extends Control

export var margin := 10
export var background_color := Color(0.1, 0.1, 0.1)
export var floor_color := Color.lightgreen
export var walker_color := Color.darkgreen
export var wall_color := Color8(69, 114, 137)

var grid: Generator.Grid = null
var offset: Vector2 = Vector2.ZERO
var middle_tile: Vector2 = Vector2.ZERO
var tile_size: Vector2 = Vector2.ZERO


func update_transform() -> void:
	tile_size = get_tile_size()
	middle_tile = get_middle_tile()
	offset = rect_size / 2 - middle_tile * tile_size

func get_middle_tile() -> Vector2:
	var x = grid.min_limit.x + grid.width() / 2
	var y = grid.min_limit.y + grid.height() / 2
	return Vector2(x, y)


func get_tile_size() -> Vector2:
	var w = rect_size.x / (grid.width() + margin)
	var h = rect_size.y / (grid.height() + margin)
	var s = min(floor(w), floor(h))
	return Vector2(s, s)

func draw_tile(tile_pos: Vector2, color: Color) -> void:
	var rect = Rect2(tile_pos * tile_size, tile_size)
	rect.position += offset
	draw_rect(rect, color)

func draw_background() -> void:
	draw_rect(Rect2(Vector2.ZERO, rect_size), background_color)

func draw_grid() -> void:
	update_transform()
	for f in grid.cave.keys():
		match grid.cave[f]:
			Generator.FLOOR: draw_tile(f, floor_color)
			Generator.WALL: draw_tile(f, wall_color)
	for w in grid.walkers:
		draw_tile(w.position, walker_color)

func _draw() -> void:
	draw_background()
	if grid:
		draw_grid()

func _ready():
	pass
