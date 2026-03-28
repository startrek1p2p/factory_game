class_name WorldRenderer
extends Node2D

var grid: GridManager
var hovered_tile: Vector2i = Vector2i(-1, -1)
var selected_building: int = 0
var selected_direction: int = 1

func _draw():
	if grid == null:
		return

	draw_grid()
	draw_hovered_tile()
	draw_buildings()
	draw_items()
	draw_build_preview()

func draw_grid():
	for x in range(grid.GRID_WIDTH + 1):
		var from = Vector2(x * grid.TILE_SIZE, 0)
		var to = Vector2(x * grid.TILE_SIZE, grid.GRID_HEIGHT * grid.TILE_SIZE)
		draw_line(from, to, Color(0.35, 0.35, 0.35), 1.0)

	for y in range(grid.GRID_HEIGHT + 1):
		var from = Vector2(0, y * grid.TILE_SIZE)
		var to = Vector2(grid.GRID_WIDTH * grid.TILE_SIZE, y * grid.TILE_SIZE)
		draw_line(from, to, Color(0.35, 0.35, 0.35), 1.0)

func draw_buildings():
	for y in range(grid.GRID_HEIGHT):
		for x in range(grid.GRID_WIDTH):
			var tile = Vector2i(x, y)
			var cell = grid.get_cell(tile)
			var building_type = cell["type"]

			if building_type == grid.BuildingType.EMPTY:
				continue

			var world_pos = grid.grid_to_world(tile)
			var rect = Rect2(world_pos, Vector2(grid.TILE_SIZE, grid.TILE_SIZE))

			match building_type:
				grid.BuildingType.WALL:
					draw_rect(rect, Color(0.5, 0.5, 0.5), true)

				grid.BuildingType.MINE:
					draw_rect(rect, Color(0.2, 0.6, 1.0), true)

				grid.BuildingType.CONVEYOR:
					draw_rect(rect, Color(1.0, 0.7, 0.2), true)
					draw_direction_arrow(rect, cell["direction"], Color(0.2, 0.2, 0.2, 1.0))

				grid.BuildingType.STORAGE:
					draw_rect(rect, Color(0.3, 0.9, 0.3), true)

func draw_items():
	for y in range(grid.GRID_HEIGHT):
		for x in range(grid.GRID_WIDTH):
			var tile = Vector2i(x, y)
			var item = grid.get_item_at(tile)

			if item == null:
				continue

			var world_pos = grid.grid_to_world(tile)
			var center = world_pos + Vector2(grid.TILE_SIZE / 2, grid.TILE_SIZE / 2)
			draw_circle(center, 6.0, Color(0.9, 0.9, 0.1))

func draw_build_preview():
	if not grid.is_tile_in_bounds(hovered_tile):
		return

	var world_pos = grid.grid_to_world(hovered_tile)
	var rect = Rect2(world_pos, Vector2(grid.TILE_SIZE, grid.TILE_SIZE))

	var color := Color(1, 1, 1, 0.3)

	match selected_building:
		grid.BuildingType.WALL:
			color = Color(0.5, 0.5, 0.5, 0.3)
		grid.BuildingType.MINE:
			color = Color(0.2, 0.6, 1.0, 0.3)
		grid.BuildingType.CONVEYOR:
			color = Color(1.0, 0.7, 0.2, 0.3)
		grid.BuildingType.STORAGE:
			color = Color(0.3, 0.9, 0.3, 0.3)

	draw_rect(rect, color, true)

	if selected_building == grid.BuildingType.CONVEYOR:
		draw_direction_arrow(rect, selected_direction, Color(0.1, 0.1, 0.1, 0.5))

func draw_hovered_tile():
	if not grid.is_tile_in_bounds(hovered_tile):
		return

	var world_pos = grid.grid_to_world(hovered_tile)
	draw_rect(
		Rect2(world_pos, Vector2(grid.TILE_SIZE, grid.TILE_SIZE)),
		Color(1.0, 1.0, 0.0, 0.18),
		true
	)

func draw_direction_arrow(rect: Rect2, direction: int, color: Color):
	var center = rect.position + rect.size * 0.5
	var dir := Vector2.ZERO

	match direction:
		grid.Direction.UP:
			dir = Vector2(0, -1)
		grid.Direction.RIGHT:
			dir = Vector2(1, 0)
		grid.Direction.DOWN:
			dir = Vector2(0, 1)
		grid.Direction.LEFT:
			dir = Vector2(-1, 0)

	var shaft_len := 11.0
	var head_len := 6.0
	var head_width := 5.0

	var tip = center + dir * shaft_len
	var base = center - dir * 4.0

	draw_line(base, tip, color, 3.0)

	var side = Vector2(-dir.y, dir.x) * head_width
	draw_line(tip, tip - dir * head_len + side, color, 2.0)
	draw_line(tip, tip - dir * head_len - side, color, 2.0)
