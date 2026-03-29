class_name WorldRenderer
extends Node2D

var grid
var hovered_tile: Vector2i = Vector2i(-1, -1)
var selected_building: int = 0
var selected_direction: int = 0

func _draw():
	if grid == null:
		return

	draw_grid()
	draw_resources()
	draw_hovered_tile()
	draw_buildings()
	draw_items()
	draw_build_preview()

func draw_grid():
	for y in range(grid.GRID_HEIGHT):
		for x in range(grid.GRID_WIDTH):
			var center = grid.grid_to_world(Vector2i(x, y))
			draw_polyline(_hex_outline_points(center), Color(0.35, 0.35, 0.35), 1.0)

func draw_buildings():
	for y in range(grid.GRID_HEIGHT):
		for x in range(grid.GRID_WIDTH):
			var tile = Vector2i(x, y)
			var cell = grid.get_cell(tile)
			var building_type = cell["type"]

			if building_type == grid.BuildingType.EMPTY:
				continue

			var center = grid.grid_to_world(tile)
			var polygon := _hex_fill_points(center)

			match building_type:
				grid.BuildingType.WALL:
					draw_colored_polygon(polygon, Color(0.5, 0.5, 0.5))

				grid.BuildingType.MINE:
					draw_colored_polygon(polygon, Color(0.2, 0.6, 1.0))
					draw_direction_arrow(center, cell["direction"], Color(0.05, 0.2, 0.35, 0.9))

				grid.BuildingType.CONVEYOR:
					draw_colored_polygon(polygon, Color(1.0, 0.7, 0.2))
					draw_direction_arrow(center, cell["direction"], Color(0.2, 0.2, 0.2, 1.0))

				grid.BuildingType.STORAGE:
					draw_colored_polygon(polygon, Color(0.3, 0.9, 0.3))

				grid.BuildingType.SOLAR_PANEL:
					draw_colored_polygon(polygon, Color(0.95, 0.9, 0.25))

func draw_resources():
	for y in range(grid.GRID_HEIGHT):
		for x in range(grid.GRID_WIDTH):
			var tile = Vector2i(x, y)
			var resource_type: int = grid.get_resource_at(tile)
			if resource_type == grid.ResourceType.NONE:
				continue

			var center = grid.grid_to_world(tile)
			draw_colored_polygon(_hex_fill_points(center), Color(0.15, 0.17, 0.2, 0.28))
			draw_polyline(_hex_outline_points(center), Color(0.55, 0.6, 0.7, 0.65), 1.4)

			match resource_type:
				grid.ResourceType.IRON:
					_draw_resource_dots(center, Color(1.0, 0.58, 0.22, 0.95))
				grid.ResourceType.BIOMASS:
					_draw_tree_icon(center)
				grid.ResourceType.TITANIUM:
					_draw_resource_dots(center, Color(0.26, 0.68, 1.0, 0.95))

func draw_items():
	for y in range(grid.GRID_HEIGHT):
		for x in range(grid.GRID_WIDTH):
			var tile = Vector2i(x, y)
			var item = grid.get_item_at(tile)

			if item == null:
				continue

			var center = grid.grid_to_world(tile)
			_draw_outlined_circle(center, 6.0, _item_color(str(item)), 1.2)

func draw_build_preview():
	if not grid.is_tile_in_bounds(hovered_tile):
		return

	var center = grid.grid_to_world(hovered_tile)
	var polygon := _hex_fill_points(center)

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
		grid.BuildingType.SOLAR_PANEL:
			color = Color(0.95, 0.9, 0.25, 0.3)

	draw_colored_polygon(polygon, color)

	if selected_building == grid.BuildingType.CONVEYOR:
		draw_direction_arrow(center, selected_direction, Color(0.1, 0.1, 0.1, 0.5))

	if selected_building == grid.BuildingType.MINE:
		draw_direction_arrow(center, selected_direction, Color(0.05, 0.2, 0.35, 0.5))

func draw_hovered_tile():
	if not grid.is_tile_in_bounds(hovered_tile):
		return

	var center = grid.grid_to_world(hovered_tile)
	draw_colored_polygon(_hex_fill_points(center), Color(1.0, 1.0, 0.0, 0.18))

func draw_direction_arrow(center: Vector2, direction: int, color: Color):
	var dir = grid.direction_to_vector(direction)

	var shaft_len = grid.HEX_RADIUS * 0.55
	var head_len = grid.HEX_RADIUS * 0.28
	var head_width = grid.HEX_RADIUS * 0.22

	var tip = center + dir * shaft_len
	var base = center - dir * (grid.HEX_RADIUS * 0.2)

	draw_line(base, tip, color, 3.0)

	var side = Vector2(-dir.y, dir.x) * head_width
	draw_line(tip, tip - dir * head_len + side, color, 2.0)
	draw_line(tip, tip - dir * head_len - side, color, 2.0)

func _hex_fill_points(center: Vector2) -> PackedVector2Array:
	var points := PackedVector2Array()
	for i in range(6):
		var angle := deg_to_rad(60.0 * i - 30.0)
		points.append(center + Vector2(cos(angle), sin(angle)) * grid.HEX_RADIUS)
	return points

func _hex_outline_points(center: Vector2) -> PackedVector2Array:
	var points := _hex_fill_points(center)
	points.append(points[0])
	return points

func _draw_resource_dots(center: Vector2, dot_color: Color) -> void:
	var offsets := [
		Vector2(-7.0, -5.0),
		Vector2(7.0, -4.0),
		Vector2(0.0, 6.0)
	]
	for offset in offsets:
		_draw_outlined_circle(center + offset, 3.2, dot_color, 1.0)

func _draw_tree_icon(center: Vector2) -> void:
	var trunk_color := Color(0.46, 0.3, 0.16, 0.95)
	var leaves_color := Color(0.3, 0.78, 0.36, 0.95)

	draw_line(center + Vector2(0.0, 7.0), center + Vector2(0.0, -1.0), trunk_color, 2.8)
	_draw_outlined_circle(center + Vector2(0.0, -6.0), 5.0, leaves_color, 1.0)
	_draw_outlined_circle(center + Vector2(-5.0, -2.5), 4.0, leaves_color, 1.0)
	_draw_outlined_circle(center + Vector2(5.0, -2.5), 4.0, leaves_color, 1.0)

func _item_color(item_name: String) -> Color:
	match item_name:
		"biomass":
			return Color(0.35, 0.86, 0.42)
		"titanium":
			return Color(0.28, 0.72, 1.0)
		_:
			return Color(1.0, 0.62, 0.24)

func _draw_outlined_circle(center: Vector2, radius: float, fill_color: Color, outline_width: float = 1.0) -> void:
	var outline_color := Color(0.02, 0.02, 0.02, 0.95)
	draw_circle(center, radius + outline_width, outline_color)
	draw_circle(center, radius, fill_color)
