tool
extends Control
class_name Generator

onready var generate_button = find_node("GenerateButton")
onready var generate_walls_button = find_node("GenerateWallsButton")
onready var export_button = find_node("ExportButton")
onready var preview = find_node("Preview")

var rng = RandomNumberGenerator.new()
enum {
	STOPPED = 0
	GEN_FLOORS
	GEN_WALLS
}

signal export_current

var running = STOPPED
var current_grid = null
# For adding walls
var floor_tiles = null

var change_dir_probability = 0.2
var spawn_walker_probability = 0.2
var kill_walker_probability = 0.1
var max_area = 10000
var max_walkers = 10
var max_walker_steps = 100
var stop_on_zero_walkers = true
var kill_by_steps = true

enum {
	EMPTY = 0
	FLOOR = 1
	WALL = 2
}
enum {
	NORTH = 0
	SOUTH
	EAST
	WEST
}
var cardinals = {
	NORTH : Vector2.UP,
	SOUTH : Vector2.DOWN,
	EAST : Vector2.RIGHT,
	WEST : Vector2.LEFT
}


func happened(rand: RandomNumberGenerator, p: float) -> bool:
	return rand.randf() < p

func random_direction() -> Vector2:
	return cardinals[rng.randi_range(0, 3)]

class Walker:
	var position := Vector2.ZERO
	var direction := Vector2.ZERO
	var steps = 0

func maybe_change_dir(walker: Walker, rand: RandomNumberGenerator, p: float):
	if happened(rand, p):
		walker.direction = random_direction()

class Grid:
	var max_limit := Vector2.ZERO
	var min_limit := Vector2.ZERO
	var cave := {}
	var walkers = []

	func width() -> float:
		return max_limit.x - min_limit.x + 1
	func height() -> float:
		return max_limit.y - min_limit.y + 1
	func size() -> Vector2:
		return Vector2(width(), height())

	func adjust_limits(v):
		max_limit = Vector2(max(v.x, max_limit.x), max(v.y, max_limit.y))
		min_limit = Vector2(min(v.x, min_limit.x), min(v.y, min_limit.y))
	
	func add_floor(v: Vector2):
		cave[v] = FLOOR
		adjust_limits(v)
	
	func has_floor(v: Vector2):
		return cave.has(v)

	func add_wall(v: Vector2):
		cave[v] = WALL


func start_generating():
	current_grid = Grid.new()
	spawn_walker(current_grid, Vector2.ZERO)
	preview.grid = current_grid
	running = GEN_FLOORS

func spawn_walker(grid: Grid, pos: Vector2):
	grid.add_floor(pos)
	var walker = Walker.new()
	walker.position = pos
	walker.direction = random_direction()
	grid.walkers.append(walker)

func maybe_spawn_walker(grid: Grid, pos: Vector2, rand: RandomNumberGenerator, p: float):
	if grid.walkers.size() >= max_walkers: return
	if happened(rand, p):
		spawn_walker(grid, pos)

func maybe_kill_walker(grid: Grid, walker: Walker, rand: RandomNumberGenerator, p: float):
	var kill = false
	if kill_by_steps:
		if walker.steps >= max_walker_steps:
			kill = true
	if happened(rand, p):
		kill = true
	if kill:
		grid.walkers.remove(grid.walkers.find(walker))

# This is here to control tick_floors rate at some point
func should_tick(_delta):
	return true

func tick_floors(grid: Grid):
	for walker in grid.walkers:
		walker.position += walker.direction
		current_grid.add_floor(walker.position)

		maybe_change_dir(walker, rng, change_dir_probability)
		maybe_spawn_walker(grid, walker.position, rng, spawn_walker_probability)
		maybe_kill_walker(grid, walker, rng, kill_walker_probability)
	
	if grid.walkers.empty():
		if stop_on_zero_walkers:
			stop_generating()
		else:
			spawn_walker(grid, Vector2(0, 0))
	if grid.cave.size() >= max_area:
		stop_generating()
	

var floor_indx = 0
# For each floor tile go outwards to each cardinal direction and add a wall if
# not present
func tick_walls(grid: Grid):
	if floor_indx >= floor_tiles.size():
		running = STOPPED
		return

	var floor_tile = floor_tiles.keys()[floor_indx]
	for dir in range(0, 4):
		var next_tile = floor_tile
		while floor_tiles.has(next_tile):
			next_tile += cardinals[dir]
		grid.add_wall(next_tile)
	floor_indx += 1

func _process(delta):
	if running == STOPPED: return
	if should_tick(delta):
		if running == GEN_FLOORS:
			tick_floors(current_grid)
		elif running == GEN_WALLS:
			tick_walls(current_grid)
		preview.update()


func _ready():
	var direction_edit = find_node("Direction")
	var spawn_edit = find_node("Spawn")
	var kill_edit = find_node("Kill")
	var stop_on_zero_walkers_toggle = find_node("StopOnZeroWalkers")
	var max_walkers_edit = find_node("MaxWalkers")
	var max_area_edit = find_node("MaxArea")
	var kill_by_steps_edit = find_node("KillBySteps")
	var max_steps_edit = find_node("MaxSteps")

	generate_button.connect("pressed", self, "_on_generate_button_pressed")
	generate_walls_button.connect("pressed", self, "_on_generate_walls_button_pressed")
	export_button.connect("pressed", self, "_on_export_button_pressed")
	direction_edit.connect("value_changed", self, "_on_dir_prob_changed")
	spawn_edit.connect("value_changed", self, "_on_spawn_prob_changed")
	kill_edit.connect("value_changed", self, "_on_kill_prob_changed")
	stop_on_zero_walkers_toggle.connect("toggled", self, "_on_stop_when_zero_walkers_toggled")
	max_walkers_edit.connect("value_changed", self, "_on_max_walkers_changed")
	max_area_edit.connect("value_changed", self, "_on_max_area_changed")
	kill_by_steps_edit.connect("toggled", self, "_on_kill_by_steps_toggled")
	max_steps_edit.connect("value_changed", self, "_on_max_steps_changed")

	change_dir_probability = direction_edit.get_value()
	spawn_walker_probability = spawn_edit.get_value()
	kill_walker_probability = kill_edit.get_value()
	max_walkers = max_walkers_edit.value
	max_area = max_area_edit.value
	stop_on_zero_walkers = stop_on_zero_walkers_toggle.pressed
	kill_by_steps = kill_by_steps_edit.pressed
	max_walker_steps = max_steps_edit.value


func _on_max_steps_changed(val: float):
	max_walker_steps = int(val)
func _on_kill_by_steps_changed(val: bool):
	kill_by_steps = val
func _on_max_walkers_changed(val: float):
	max_walkers = int(val)
func _on_max_area_changed(val: float):
	max_area = int(val)
func _on_stop_when_zero_walkers_toggled(val: bool):
	stop_on_zero_walkers = val
func _on_dir_prob_changed(value: float):
	change_dir_probability = value
func _on_spawn_prob_changed(value: float):
	spawn_walker_probability = value
func _on_kill_prob_changed(value: float):
	kill_walker_probability = value


func stop_generating():
	running = STOPPED
	generate_button.text = "Generate"
	current_grid.walkers.clear()
	if !current_grid.cave.empty():
		generate_walls_button.disabled = false
		export_button.disabled = false
		floor_tiles = current_grid.cave.duplicate()


func _on_generate_button_pressed():
	if running:
		stop_generating()
		return
	generate_button.text = "Stop"
	generate_walls_button.disabled = true
	export_button.disabled = true
	start_generating()

func _on_generate_walls_button_pressed():
	running = GEN_WALLS
	floor_indx = 0

func _on_export_button_pressed():
	emit_signal("export_current")

func export_current_to_tilemap(tilemap: TileMap):
	tilemap.clear()
	print(tilemap.tile_set.get_tiles_ids())
	for tile in current_grid.cave.keys():
		tilemap.set_cell(tile.x, tile.y, current_grid.cave[tile] - 1)
