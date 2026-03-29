class_name Simulation
extends RefCounted

var grid: GridManager
var storage_count: int = 0
var planned_moves: Array = []
var reserved_targets: Dictionary = {}

func _init(grid_manager: GridManager):
	grid = grid_manager

func tick():
	planned_moves.clear()
	reserved_targets.clear()

	# Faza A: planowanie ruchów bez modyfikowania stanu grida.
	collect_mine_moves()
	collect_conveyor_moves()

	# Faza B: zatwierdzamy i aplikujemy tylko zaakceptowane ruchy.
	apply_planned_moves()

func collect_mine_moves():
	for y in range(grid.GRID_HEIGHT):
		for x in range(grid.GRID_WIDTH):
			var tile = Vector2i(x, y)
			var cell = grid.get_cell(tile)

			if cell["type"] != grid.BuildingType.MINE:
				continue

			if cell["item"] == null:
				cell["item"] = "ore"

			if cell["item"] == null:
				continue

			plan_move(tile, cell["direction"], cell["item"], "mine")

func collect_conveyor_moves():
	for y in range(grid.GRID_HEIGHT):
		for x in range(grid.GRID_WIDTH):
			var tile = Vector2i(x, y)
			var cell = grid.get_cell(tile)

			if cell["type"] != grid.BuildingType.CONVEYOR:
				continue

			if cell["item"] == null:
				continue

			plan_move(tile, cell["direction"], cell["item"], "conveyor")

func plan_move(from_tile: Vector2i, direction: int, item, source_type: String):
	var next_tile = grid.get_neighbor_tile(from_tile, direction)

	if not grid.is_tile_in_bounds(next_tile):
		return

	var next_cell = grid.get_cell(next_tile)
	var is_valid_target = false

	if next_cell["type"] == grid.BuildingType.CONVEYOR and next_cell["item"] == null:
		is_valid_target = true
	elif next_cell["type"] == grid.BuildingType.STORAGE:
		is_valid_target = true

	if not is_valid_target:
		return

	var target_key = "%s,%s" % [next_tile.x, next_tile.y]

	# Reguła kolizji: pierwszy ruch rezerwuje cel, kolejne do tego samego pola odpadają.
	# Dzięki kolejności planowania kopalnie mają priorytet nad przenośnikami.
	if reserved_targets.has(target_key):
		return

	reserved_targets[target_key] = true
	planned_moves.append({
		"from": from_tile,
		"to": next_tile,
		"item": item,
		"source": source_type
	})

func apply_planned_moves():
	for move in planned_moves:
		# Czyścimy źródło tylko dla zaakceptowanych (zarezerwowanych) ruchów.
		grid.set_item_at(move["from"], null)

		var to_tile = move["to"]
		var to_cell = grid.get_cell(to_tile)

		if to_cell["type"] == grid.BuildingType.CONVEYOR:
			grid.set_item_at(to_tile, move["item"])
		elif to_cell["type"] == grid.BuildingType.STORAGE:
			storage_count += 1
