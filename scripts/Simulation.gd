class_name Simulation
extends RefCounted

var grid: GridManager
var storage_count: int = 0

func _init(grid_manager: GridManager):
	grid = grid_manager

func tick():
	process_mines()
	process_conveyors()

func process_mines():
	var moves := []

	for y in range(grid.GRID_HEIGHT):
		for x in range(grid.GRID_WIDTH):
			var tile = Vector2i(x, y)
			var cell = grid.get_cell(tile)

			if cell["type"] != grid.BuildingType.MINE:
				continue

			if cell["item"] == null:
				cell["item"] = "ore"

			if cell["item"] != null:
				for dir in _direction_priority(cell["direction"]):
					var next_tile = grid.get_neighbor_tile(tile, dir)

					if not grid.is_tile_in_bounds(next_tile):
						continue

					var next_cell = grid.get_cell(next_tile)

					if next_cell["type"] == grid.BuildingType.CONVEYOR and next_cell["item"] == null:
						moves.append({
							"from": tile,
							"to": next_tile,
							"item": cell["item"]
						})
						break

					elif next_cell["type"] == grid.BuildingType.STORAGE:
						moves.append({
							"from": tile,
							"to": next_tile,
							"item": cell["item"]
						})
						break

	for move in moves:
		grid.set_item_at(move["from"], null)

		var to_tile = move["to"]
		var to_cell = grid.get_cell(to_tile)

		if to_cell["type"] == grid.BuildingType.CONVEYOR:
			grid.set_item_at(to_tile, move["item"])
		elif to_cell["type"] == grid.BuildingType.STORAGE:
			storage_count += 1

func process_conveyors():
	var moves := []

	for y in range(grid.GRID_HEIGHT):
		for x in range(grid.GRID_WIDTH):
			var tile = Vector2i(x, y)
			var cell = grid.get_cell(tile)

			if cell["type"] != grid.BuildingType.CONVEYOR:
				continue

			if cell["item"] == null:
				continue

			var dir = cell["direction"]
			var next_tile = grid.get_neighbor_tile(tile, dir)

			if not grid.is_tile_in_bounds(next_tile):
				continue

			var next_cell = grid.get_cell(next_tile)

			if next_cell["type"] == grid.BuildingType.CONVEYOR and next_cell["item"] == null:
				moves.append({
					"from": tile,
					"to": next_tile,
					"item": cell["item"]
				})

			elif next_cell["type"] == grid.BuildingType.STORAGE:
				moves.append({
					"from": tile,
					"to": next_tile,
					"item": cell["item"]
				})

	for move in moves:
		grid.set_item_at(move["from"], null)

		var to_tile = move["to"]
		var to_cell = grid.get_cell(to_tile)

		if to_cell["type"] == grid.BuildingType.CONVEYOR:
			grid.set_item_at(to_tile, move["item"])
		elif to_cell["type"] == grid.BuildingType.STORAGE:
			storage_count += 1

func _direction_priority(preferred_direction: int) -> Array[int]:
	var ordered: Array[int] = [preferred_direction]
	for direction in range(6):
		if direction == preferred_direction:
			continue
		ordered.append(direction)
	return ordered
