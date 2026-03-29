class_name WorldRenderer
extends Node2D

var grid
var hovered_tile: Vector2i = Vector2i(-1, -1)
var selected_building: int = 0
var selected_direction: int = 0
const ENERGY_LINK_COLOR := Color(1.0, 0.95, 0.75, 0.9)
const ENERGY_LINK_WIDTH := 2.2

func _draw():
	if grid == null:
		return

	draw_grid()
	draw_hovered_tile()
	draw_buildings()
	draw_energy_links()
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

				grid.BuildingType.ENERGY_NODE:
					draw_colored_polygon(polygon, Color(0.65, 0.45, 0.95))

func draw_items():
	for y in range(grid.GRID_HEIGHT):
		for x in range(grid.GRID_WIDTH):
			var tile = Vector2i(x, y)
			var item = grid.get_item_at(tile)

			if item == null:
				continue

			var center = grid.grid_to_world(tile)
			draw_circle(center, 6.0, Color(0.9, 0.9, 0.1))

func draw_energy_links():
	var all_energy_tiles: Array[Vector2i] = []
	var energy_nodes: Array[Vector2i] = []

	for y in range(grid.GRID_HEIGHT):
		for x in range(grid.GRID_WIDTH):
			var tile: Vector2i = Vector2i(x, y)
			var building_type: int = int(grid.get_building_at(tile))
			if not _is_energy_link_candidate(building_type):
				continue
			all_energy_tiles.append(tile)
			if building_type == grid.BuildingType.ENERGY_NODE:
				energy_nodes.append(tile)

	for node_tile in energy_nodes:
		var node_center: Vector2 = grid.grid_to_world(node_tile)
		for target_tile in all_energy_tiles:
			if target_tile == node_tile:
				continue
			if not _is_in_energy_node_range(node_tile, target_tile):
				continue
			var target_center: Vector2 = grid.grid_to_world(target_tile)
			draw_line(node_center, target_center, ENERGY_LINK_COLOR, ENERGY_LINK_WIDTH)

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
		grid.BuildingType.ENERGY_NODE:
			color = Color(0.65, 0.45, 0.95, 0.3)

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

func _is_energy_link_candidate(building_type: int) -> bool:
	return building_type == grid.BuildingType.SOLAR_PANEL \
		or building_type == grid.BuildingType.ENERGY_NODE \
		or building_type == grid.BuildingType.MINE

func _is_in_energy_node_range(node_tile: Vector2i, target_tile: Vector2i) -> bool:
	return _hex_distance(node_tile, target_tile) <= grid.ENERGY_NODE_RANGE

func _hex_distance(a: Vector2i, b: Vector2i) -> int:
	var axial_a: Vector2i = grid.offset_to_axial(a)
	var axial_b: Vector2i = grid.offset_to_axial(b)
	var dq := axial_a.x - axial_b.x
	var dr := axial_a.y - axial_b.y
	var ds := (-axial_a.x - axial_a.y) - (-axial_b.x - axial_b.y)
	return int((abs(dq) + abs(dr) + abs(ds)) / 2)

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
