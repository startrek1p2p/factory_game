class_name Simulation
extends RefCounted

const EconomyStateScript = preload("res://scripts/models/EconomyState.gd")

var grid
var economy_state := EconomyStateScript.new()
var planned_moves: Array = []
var reserved_targets: Dictionary = {}
var reserved_sources: Dictionary = {}
var active_mines: Dictionary = {}
var mine_to_component: Dictionary = {}
var component_has_panel: Dictionary = {}
var powered_mines_count: int = 0
var unpowered_mines_count: int = 0

var energy_available: int = 0
const SOLAR_OUTPUT_PER_TICK := 10
const MINE_ENERGY_COST_PER_TICK := 10
const ENERGY_NODE_CAPACITY := -1

func _init(grid_manager):
	grid = grid_manager
	energy_available = 0

func tick():
	planned_moves.clear()
	reserved_targets.clear()
	reserved_sources.clear()
	active_mines.clear()

	# Jawna semantyka ticka: "max 1 ruch na item/tick" (bez pipeline'u).
	# 1) input_snapshot = stan wejściowy odczytany raz na początku ticka.
	# 2) planowanie ruchów bazuje wyłącznie na input_snapshot.
	# 3) next_state = stan wyjściowy tworzony po planowaniu i commitowany na końcu.
	# Dzięki temu item wygenerowany lub przesunięty w tym ticku nie jest ponownie
	# przetwarzany przez kolejne etapy tego samego ticka.
	var input_snapshot: Dictionary = snapshot_items_from_grid()
	var next_state: Dictionary = input_snapshot.duplicate(true)
	energy_available = stage_collect_energy_from_solar_panels()
	build_energy_network_components()
	prepare_active_mines_from_snapshot()

	stage_mines_generate_into_next_state(input_snapshot, next_state)
	collect_mine_moves_from_snapshot(input_snapshot)
	collect_conveyor_moves_from_snapshot(input_snapshot)
	apply_planned_moves_to_next_state(next_state)
	commit_next_state_to_grid(next_state)
	sync_energy_to_economy_state()

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
			if not is_mine_powered(tile):
				continue
			if not is_mine_active(tile):
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
			if not is_mine_powered(tile):
				continue
			if not is_mine_active(tile):
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
			economy_state.add_resource(EconomyStateScript.RESOURCE_MINERALS, 1)

func commit_next_state_to_grid(next_state: Dictionary):
	for tile in next_state.keys():
		grid.set_item_at(tile, next_state[tile])

func stage_collect_energy_from_solar_panels() -> int:
	var generated_energy := 0

	for y in range(grid.GRID_HEIGHT):
		for x in range(grid.GRID_WIDTH):
			var tile = Vector2i(x, y)
			var cell = grid.get_cell(tile)
			if cell["type"] == grid.BuildingType.SOLAR_PANEL:
				generated_energy += SOLAR_OUTPUT_PER_TICK

	return generated_energy

func prepare_active_mines_from_snapshot() -> void:
	active_mines.clear()
	powered_mines_count = 0
	unpowered_mines_count = 0

	if MINE_ENERGY_COST_PER_TICK <= 0:
		for y in range(grid.GRID_HEIGHT):
			for x in range(grid.GRID_WIDTH):
				var tile = Vector2i(x, y)
				var cell = grid.get_cell(tile)
				if cell["type"] != grid.BuildingType.MINE:
					continue
				if not is_mine_powered(tile):
					unpowered_mines_count += 1
					continue
				active_mines[tile] = true
				powered_mines_count += 1
		return

	var connected_mines: Array[Vector2i] = []
	for y in range(grid.GRID_HEIGHT):
		for x in range(grid.GRID_WIDTH):
			var tile = Vector2i(x, y)
			var cell = grid.get_cell(tile)
			if cell["type"] != grid.BuildingType.MINE:
				continue
			if not is_mine_powered(tile):
				unpowered_mines_count += 1
				continue
			connected_mines.append(tile)

	for tile in connected_mines:
		if energy_available < MINE_ENERGY_COST_PER_TICK:
			break

		energy_available -= MINE_ENERGY_COST_PER_TICK
		active_mines[tile] = true
		powered_mines_count += 1

	unpowered_mines_count += connected_mines.size() - powered_mines_count

func is_mine_active(tile: Vector2i) -> bool:
	return active_mines.has(tile)

func sync_energy_to_economy_state() -> void:
	economy_state.resources[EconomyStateScript.RESOURCE_ENERGY] = energy_available

func build_energy_network_components() -> void:
	mine_to_component.clear()
	component_has_panel.clear()
	var traversable_tiles: Dictionary = {}

	for y in range(grid.GRID_HEIGHT):
		for x in range(grid.GRID_WIDTH):
			var tile = Vector2i(x, y)
			var building_type = grid.get_building_at(tile)
			if _is_energy_network_tile(building_type):
				traversable_tiles[tile] = true

	var visited: Dictionary = {}
	var component_id := 0

	for tile in traversable_tiles.keys():
		if visited.has(tile):
			continue
		_build_component_from_seed(tile, component_id, traversable_tiles, visited)
		component_id += 1

func _build_component_from_seed(seed_tile: Vector2i, component_id: int, traversable_tiles: Dictionary, visited: Dictionary) -> void:
	var stack: Array[Vector2i] = [seed_tile]
	visited[seed_tile] = true
	var has_panel := false

	while not stack.is_empty():
		var current_tile: Vector2i = stack.pop_back()
		var current_type = grid.get_building_at(current_tile)

		if current_type == grid.BuildingType.SOLAR_PANEL:
			has_panel = true
		elif current_type == grid.BuildingType.MINE:
			mine_to_component[current_tile] = component_id

		for direction in range(6):
			var neighbor_tile = grid.get_neighbor_tile(current_tile, direction)
			if not grid.is_tile_in_bounds(neighbor_tile):
				continue
			if not traversable_tiles.has(neighbor_tile):
				continue
			if visited.has(neighbor_tile):
				continue

			visited[neighbor_tile] = true
			stack.append(neighbor_tile)

	component_has_panel[component_id] = has_panel

func _is_energy_network_tile(building_type: int) -> bool:
	return building_type == grid.BuildingType.SOLAR_PANEL \
		or building_type == grid.BuildingType.ENERGY_NODE \
		or building_type == grid.BuildingType.MINE

func is_mine_powered(tile: Vector2i) -> bool:
	var component_id = mine_to_component.get(tile, null)
	if component_id == null:
		return false
	return bool(component_has_panel.get(component_id, false))

func get_power_debug_stats() -> Dictionary:
	return {
		"powered_mines": powered_mines_count,
		"unpowered_mines": unpowered_mines_count
	}
