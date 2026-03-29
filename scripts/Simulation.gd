class_name Simulation
extends RefCounted

var grid: GridManager
var storage_count: int = 0
var planned_moves: Array = []
var reserved_targets: Dictionary = {}
var reserved_sources: Dictionary = {}

func _init(grid_manager: GridManager):
	grid = grid_manager

func tick():
	planned_moves.clear()
	reserved_targets.clear()
	reserved_sources.clear()

	# Jawna semantyka ticka: "max 1 ruch na item/tick" (bez pipeline'u).
	# 1) input_snapshot = stan wejściowy odczytany raz na początku ticka.
	# 2) planowanie ruchów bazuje wyłącznie na input_snapshot.
	# 3) next_state = stan wyjściowy tworzony po planowaniu i commitowany na końcu.
	# Dzięki temu item wygenerowany lub przesunięty w tym ticku nie jest ponownie
	# przetwarzany przez kolejne etapy tego samego ticka.
	var input_snapshot: Dictionary = snapshot_items_from_grid()
	var next_state: Dictionary = input_snapshot.duplicate(true)

	stage_mines_generate_into_next_state(input_snapshot, next_state)
	collect_mine_moves_from_snapshot(input_snapshot)
	collect_conveyor_moves_from_snapshot(input_snapshot)
	apply_planned_moves_to_next_state(next_state)
	commit_next_state_to_grid(next_state)

func snapshot_items_from_grid() -> Dictionary:
	var snapshot: Dictionary = {}

	for y in range(grid.GRID_HEIGHT):
		for x in range(grid.GRID_WIDTH):
			var tile = Vector2i(x, y)
			var cell = grid.get_cell(tile)
			snapshot[tile] = cell["item"]

	return snapshot

func stage_mines_generate_into_next_state(input_snapshot: Dictionary, next_state: Dictionary):
	for y in range(grid.GRID_HEIGHT):
		for x in range(grid.GRID_WIDTH):
			var tile = Vector2i(x, y)
			var cell = grid.get_cell(tile)

			if cell["type"] != grid.BuildingType.MINE:
				continue

			if input_snapshot[tile] == null:
				next_state[tile] = "ore"

func collect_mine_moves_from_snapshot(input_snapshot: Dictionary):
	for y in range(grid.GRID_HEIGHT):
		for x in range(grid.GRID_WIDTH):
			var tile = Vector2i(x, y)
			var cell = grid.get_cell(tile)

			if cell["type"] != grid.BuildingType.MINE:
				continue

			var item = input_snapshot[tile]
			if item == null:
				item = "ore"

			plan_single_step_move_from_snapshot(tile, cell["direction"], item, input_snapshot, "mine")

func collect_conveyor_moves_from_snapshot(input_snapshot: Dictionary):
	for y in range(grid.GRID_HEIGHT):
		for x in range(grid.GRID_WIDTH):
			var tile = Vector2i(x, y)
			var cell = grid.get_cell(tile)

			if cell["type"] != grid.BuildingType.CONVEYOR:
				continue

			var item = input_snapshot[tile]
			if item == null:
				continue

			plan_single_step_move_from_snapshot(tile, cell["direction"], item, input_snapshot, "conveyor")

func plan_single_step_move_from_snapshot(from_tile: Vector2i, direction: int, item, input_snapshot: Dictionary, source_type: String):
	if item == null:
		return

	# Reguła "max 1 ruch na item/tick": jedno źródło może zostać zaplanowane tylko raz.
	if reserved_sources.has(from_tile):
		return

	var next_tile = grid.get_neighbor_tile(from_tile, direction)

	if not grid.is_tile_in_bounds(next_tile):
		return

	var next_cell = grid.get_cell(next_tile)
	var is_valid_target = false

	# Brak pipeline'u: zajętość celu liczymy na podstawie input_snapshot.
	# Jeśli przenośnik był zajęty na wejściu ticka, nie można do niego wejść
	# w tym ticku, nawet gdy jego item opuszcza go w tym samym kroku.
	if next_cell["type"] == grid.BuildingType.CONVEYOR and input_snapshot[next_tile] == null:
		is_valid_target = true
	elif next_cell["type"] == grid.BuildingType.STORAGE:
		is_valid_target = true

	if not is_valid_target:
		return

	# Kolizje na celu rozwiązujemy przez rezerwację: pierwszy wygrywa.
	# Kolejność etapów (mine -> conveyor) daje priorytet kopalniom.
	if reserved_targets.has(next_tile):
		return

	reserved_targets[next_tile] = true
	reserved_sources[from_tile] = true
	planned_moves.append({
		"from": from_tile,
		"to": next_tile,
		"item": item,
		"source": source_type
	})

func apply_planned_moves_to_next_state(next_state: Dictionary):
	for move in planned_moves:
		next_state[move["from"]] = null

		var to_tile = move["to"]
		var to_cell = grid.get_cell(to_tile)

		if to_cell["type"] == grid.BuildingType.CONVEYOR:
			next_state[to_tile] = move["item"]
		elif to_cell["type"] == grid.BuildingType.STORAGE:
			storage_count += 1

func commit_next_state_to_grid(next_state: Dictionary):
	for tile in next_state.keys():
		grid.set_item_at(tile, next_state[tile])
