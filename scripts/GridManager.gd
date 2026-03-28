class_name GridManager
extends RefCounted

const TILE_SIZE := 32
const GRID_WIDTH := 40
const GRID_HEIGHT := 25

enum BuildingType {
	EMPTY,
	WALL,
	MINE,
	CONVEYOR,
	STORAGE
}

enum Direction {
	UP,
	RIGHT,
	DOWN,
	LEFT
}

var grid_data: Array = []

func _init():
	initialize_grid()

func initialize_grid():
	grid_data.clear()

	for y in range(GRID_HEIGHT):
		var row := []
		for x in range(GRID_WIDTH):
			row.append(create_empty_cell())
		grid_data.append(row)

func create_empty_cell() -> Dictionary:
	return {
		"type": BuildingType.EMPTY,
		"direction": Direction.RIGHT,
		"item": null
	}

func create_cell(building_type: int, direction: int = Direction.RIGHT) -> Dictionary:
	return {
		"type": building_type,
		"direction": direction,
		"item": null
	}

func is_tile_in_bounds(tile: Vector2i) -> bool:
	return tile.x >= 0 and tile.y >= 0 and tile.x < GRID_WIDTH and tile.y < GRID_HEIGHT

func place_building(tile: Vector2i, building_type: int, direction: int = Direction.RIGHT) -> bool:
	if not is_tile_in_bounds(tile):
		return false

	if building_type == BuildingType.EMPTY:
		grid_data[tile.y][tile.x] = create_empty_cell()
		return true

	if grid_data[tile.y][tile.x]["type"] != BuildingType.EMPTY:
		return false

	grid_data[tile.y][tile.x] = create_cell(building_type, direction)
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
	return Vector2i(
		int(floor(world_pos.x / TILE_SIZE)),
		int(floor(world_pos.y / TILE_SIZE))
	)

func grid_to_world(grid_pos: Vector2i) -> Vector2:
	return Vector2(
		grid_pos.x * TILE_SIZE,
		grid_pos.y * TILE_SIZE
	)

func direction_to_vector(direction: int) -> Vector2i:
	match direction:
		Direction.UP:
			return Vector2i(0, -1)
		Direction.RIGHT:
			return Vector2i(1, 0)
		Direction.DOWN:
			return Vector2i(0, 1)
		Direction.LEFT:
			return Vector2i(-1, 0)

	return Vector2i.ZERO
