class_name GridManager
extends RefCounted

const HEX_RADIUS := 20.0
const SQRT3 := 1.7320508075688772
const GRID_WIDTH := 40
const GRID_HEIGHT := 25
const ENERGY_NODE_RANGE := 4

# Dla kompatybilności z istniejącymi odwołaniami.
const TILE_SIZE := int(HEX_RADIUS * 2.0)

enum BuildingType {
	EMPTY,
	WALL,
	MINE,
	CONVEYOR,
	STORAGE,
	SOLAR_PANEL,
	ENERGY_NODE
}

enum ResourceType {
	NONE,
	IRON,
	BIOMASS,
	TITANIUM
}

const MIN_RESOURCE_NODES_PER_TYPE := 2
const MAX_RESOURCE_NODES_PER_TYPE := 5

enum Direction {
	EAST,
	NORTHEAST,
	NORTHWEST,
	WEST,
	SOUTHWEST,
	SOUTHEAST
}

var grid_data: Array = []

func _init():
	initialize_grid()

func initialize_grid():
	randomize()
	grid_data.clear()

	for y in range(GRID_HEIGHT):
		var row := []
		for x in range(GRID_WIDTH):
			row.append(create_empty_cell())
		grid_data.append(row)

	generate_resource_nodes()

func create_empty_cell(resource_type: int = ResourceType.NONE) -> Dictionary:
	return {
		"type": BuildingType.EMPTY,
		"direction": Direction.EAST,
		"item": null,
		"resource": resource_type
	}

func create_cell(building_type: int, direction: int = Direction.EAST, resource_type: int = ResourceType.NONE) -> Dictionary:
	return {
		"type": building_type,
		"direction": direction,
		"item": null,
		"resource": resource_type
	}

func get_resource_at(tile: Vector2i) -> int:
	return get_cell(tile).get("resource", ResourceType.NONE)

func has_resource(tile: Vector2i) -> bool:
	return get_resource_at(tile) != ResourceType.NONE

func generate_resource_nodes() -> void:
	_place_resource_group(ResourceType.IRON)
	_place_resource_group(ResourceType.BIOMASS)
	_place_resource_group(ResourceType.TITANIUM)

func _place_resource_group(resource_type: int) -> void:
	var target_amount := randi_range(MIN_RESOURCE_NODES_PER_TYPE, MAX_RESOURCE_NODES_PER_TYPE)
	var placed := 0
	var attempts := 0
	var max_attempts := GRID_WIDTH * GRID_HEIGHT * 6

	while placed < target_amount and attempts < max_attempts:
		attempts += 1
		var tile := Vector2i(randi_range(0, GRID_WIDTH - 1), randi_range(0, GRID_HEIGHT - 1))
		if has_resource(tile):
			continue

		grid_data[tile.y][tile.x]["resource"] = resource_type
		placed += 1

	if placed < MIN_RESOURCE_NODES_PER_TYPE:
		for y in range(GRID_HEIGHT):
			for x in range(GRID_WIDTH):
				if placed >= MIN_RESOURCE_NODES_PER_TYPE:
					return

				var tile := Vector2i(x, y)
				if has_resource(tile):
					continue

				grid_data[tile.y][tile.x]["resource"] = resource_type
				placed += 1

func is_tile_in_bounds(tile: Vector2i) -> bool:
	return tile.x >= 0 and tile.y >= 0 and tile.x < GRID_WIDTH and tile.y < GRID_HEIGHT

func place_building(tile: Vector2i, building_type: int, direction: int = Direction.EAST) -> bool:
	if not is_tile_in_bounds(tile):
		return false

	if building_type == BuildingType.EMPTY:
		var resource_type: int = get_resource_at(tile)
		grid_data[tile.y][tile.x] = create_empty_cell(resource_type)
		return true

	if grid_data[tile.y][tile.x]["type"] != BuildingType.EMPTY:
		return false

	var resource_type: int = get_resource_at(tile)
	grid_data[tile.y][tile.x] = create_cell(building_type, direction, resource_type)
	return true

func get_cell(tile: Vector2i) -> Dictionary:
	if not is_tile_in_bounds(tile):
		return create_empty_cell()
	return grid_data[tile.y][tile.x]

func get_building_at(tile: Vector2i) -> int:
	return get_cell(tile)["type"]

func get_direction_at(tile: Vector2i) -> int:
	return get_cell(tile)["direction"]

func get_item_at(tile: Vector2i):
	return get_cell(tile)["item"]

func set_item_at(tile: Vector2i, item) -> void:
	if not is_tile_in_bounds(tile):
		return
	grid_data[tile.y][tile.x]["item"] = item

func has_item(tile: Vector2i) -> bool:
	return get_item_at(tile) != null

func world_to_grid(world_pos: Vector2) -> Vector2i:
	var qf := (SQRT3 / 3.0 * world_pos.x - 1.0 / 3.0 * world_pos.y) / HEX_RADIUS
	var rf := (2.0 / 3.0 * world_pos.y) / HEX_RADIUS
	var rounded_axial := _axial_round(Vector2(qf, rf))
	return axial_to_offset(rounded_axial)

func grid_to_world(grid_pos: Vector2i) -> Vector2:
	var axial := offset_to_axial(grid_pos)
	return axial_to_world(axial)

func axial_to_world(axial: Vector2i) -> Vector2:
	var x := HEX_RADIUS * SQRT3 * (axial.x + axial.y / 2.0)
	var y := HEX_RADIUS * 1.5 * axial.y
	return Vector2(x, y)

func offset_to_axial(tile: Vector2i) -> Vector2i:
	var q := tile.x - int((tile.y - (tile.y & 1)) / 2)
	var r := tile.y
	return Vector2i(q, r)

func axial_to_offset(axial: Vector2i) -> Vector2i:
	var col := axial.x + int((axial.y - (axial.y & 1)) / 2)
	var row := axial.y
	return Vector2i(col, row)

func _axial_round(frac_axial: Vector2) -> Vector2i:
	var x := frac_axial.x
	var z := frac_axial.y
	var y := -x - z

	var rx := roundi(x)
	var ry := roundi(y)
	var rz := roundi(z)

	var x_diff := absf(float(rx) - x)
	var y_diff := absf(float(ry) - y)
	var z_diff := absf(float(rz) - z)

	if x_diff > y_diff and x_diff > z_diff:
		rx = -ry - rz
	elif y_diff > z_diff:
		ry = -rx - rz
	else:
		rz = -rx - ry

	return Vector2i(rx, rz)

func get_neighbor_tile(tile: Vector2i, direction: int) -> Vector2i:
	var row_is_odd := (tile.y & 1) == 1

	if row_is_odd:
		match direction:
			Direction.EAST:
				return tile + Vector2i(1, 0)
			Direction.NORTHEAST:
				return tile + Vector2i(1, -1)
			Direction.NORTHWEST:
				return tile + Vector2i(0, -1)
			Direction.WEST:
				return tile + Vector2i(-1, 0)
			Direction.SOUTHWEST:
				return tile + Vector2i(0, 1)
			Direction.SOUTHEAST:
				return tile + Vector2i(1, 1)
	else:
		match direction:
			Direction.EAST:
				return tile + Vector2i(1, 0)
			Direction.NORTHEAST:
				return tile + Vector2i(0, -1)
			Direction.NORTHWEST:
				return tile + Vector2i(-1, -1)
			Direction.WEST:
				return tile + Vector2i(-1, 0)
			Direction.SOUTHWEST:
				return tile + Vector2i(-1, 1)
			Direction.SOUTHEAST:
				return tile + Vector2i(0, 1)

	return tile

func direction_to_vector(direction: int) -> Vector2:
	var angle_deg := -60.0 * float(direction)
	var angle_rad := deg_to_rad(angle_deg)
	return Vector2(cos(angle_rad), sin(angle_rad))
