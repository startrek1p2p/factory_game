class_name Simulation
extends RefCounted

const PRESSURE_CONFIG_PATH := "res://data/planet_pressure_config.json"

var grid: GridManager
var storage_count: int = 0

var oxygen: float = 12.0
var heat: float = 8.0
var bio_energy: float = 5.0

var planet_pressure: float = 0.0
var pressure_band: Dictionary = {}
var pressure_config: Dictionary = {}

var wave_tick_counter: int = 0
var wave_count: int = 0
var last_wave_composition: Dictionary = {
	"scouts": 0,
	"brutes": 0,
	"fliers": 0
}
var last_anomaly_tiles: Array[Vector2i] = []

func _init(grid_manager: GridManager):
	grid = grid_manager
	load_pressure_config()
	pressure_band = get_band_for_pressure(planet_pressure)

func tick():
	process_mines()
	process_conveyors()
	update_terraform_indicators()
	update_planet_pressure()
	process_waves_and_anomalies()

func load_pressure_config():
	if not FileAccess.file_exists(PRESSURE_CONFIG_PATH):
		push_warning("Brak konfiguracji presji planety: %s" % PRESSURE_CONFIG_PATH)
		pressure_config = _build_fallback_pressure_config()
		return

	var file := FileAccess.open(PRESSURE_CONFIG_PATH, FileAccess.READ)
	if file == null:
		pressure_config = _build_fallback_pressure_config()
		return

	var parsed = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		push_warning("Niepoprawny format konfiguracji presji, używam fallbacku")
		pressure_config = _build_fallback_pressure_config()
		return

	pressure_config = parsed

func _build_fallback_pressure_config() -> Dictionary:
	return {
		"base_pressure_gain_per_tick": 0.2,
		"base_wave_interval_ticks": 20,
		"base_anomaly_risk": 0.01,
		"terraform_pressure_weights": {
			"oxygen": 0.4,
			"heat": 0.35,
			"bio_energy": 0.25
		},
		"pressure_bands": [
			{
				"id": "stable",
				"label": "Stabilna",
				"min": 0.0,
				"max": 25.0,
				"wave_frequency_multiplier": 0.85,
				"wave_comp_spike": 0.8,
				"anomaly_risk_multiplier": 0.7,
				"alarm_color": "#4EC979"
			},
			{
				"id": "unstable",
				"label": "Niestabilna",
				"min": 25.0,
				"max": 55.0,
				"wave_frequency_multiplier": 1.0,
				"wave_comp_spike": 1.0,
				"anomaly_risk_multiplier": 1.0,
				"alarm_color": "#EBCB4C"
			},
			{
				"id": "critical",
				"label": "Krytyczna",
				"min": 55.0,
				"max": 80.0,
				"wave_frequency_multiplier": 1.35,
				"wave_comp_spike": 1.35,
				"anomaly_risk_multiplier": 1.5,
				"alarm_color": "#F18B41"
			},
			{
				"id": "overload",
				"label": "Przeciążenie",
				"min": 80.0,
				"max": 100.0,
				"wave_frequency_multiplier": 1.75,
				"wave_comp_spike": 1.8,
				"anomaly_risk_multiplier": 2.2,
				"alarm_color": "#E04F5F"
			}
		]
	}

func update_terraform_indicators():
	# Tymczasowy model wzrostu wskaźników od postępu ekonomii.
	oxygen = clampf(oxygen + 0.03 + float(storage_count) * 0.002, 0.0, 100.0)
	heat = clampf(heat + 0.025 + float(storage_count) * 0.0018, 0.0, 100.0)
	bio_energy = clampf(bio_energy + 0.02 + float(storage_count) * 0.0015, 0.0, 100.0)

func update_planet_pressure():
	var weights: Dictionary = pressure_config.get("terraform_pressure_weights", {})
	var oxygen_w: float = float(weights.get("oxygen", 0.4))
	var heat_w: float = float(weights.get("heat", 0.35))
	var bio_w: float = float(weights.get("bio_energy", 0.25))
	var normalized_terraform := (oxygen / 100.0) * oxygen_w + (heat / 100.0) * heat_w + (bio_energy / 100.0) * bio_w
	var base_gain: float = float(pressure_config.get("base_pressure_gain_per_tick", 0.2))

	planet_pressure = clampf(planet_pressure + base_gain * (1.0 + normalized_terraform), 0.0, 100.0)
	pressure_band = get_band_for_pressure(planet_pressure)

func get_band_for_pressure(value: float) -> Dictionary:
	var bands: Array = pressure_config.get("pressure_bands", [])
	for band in bands:
		var min_v: float = float(band.get("min", 0.0))
		var max_v: float = float(band.get("max", 100.0))
		if value >= min_v and value < max_v:
			return band

	if bands.is_empty():
		return {
			"id": "unknown",
			"label": "Brak danych",
			"wave_frequency_multiplier": 1.0,
			"wave_comp_spike": 1.0,
			"anomaly_risk_multiplier": 1.0,
			"alarm_color": "#EBCB4C"
		}

	return bands[bands.size() - 1]

func process_waves_and_anomalies():
	wave_tick_counter += 1

	var base_interval: float = float(pressure_config.get("base_wave_interval_ticks", 20))
	var frequency_multiplier: float = float(pressure_band.get("wave_frequency_multiplier", 1.0))
	var interval: int = maxi(1, int(round(base_interval / frequency_multiplier)))

	if wave_tick_counter >= interval:
		wave_tick_counter = 0
		spawn_wave()

	roll_local_anomalies()

func spawn_wave():
	wave_count += 1
	var spike: float = float(pressure_band.get("wave_comp_spike", 1.0))
	var base_strength: int = 4 + int(planet_pressure / 18.0)

	last_wave_composition = {
		"scouts": maxi(1, int(round(base_strength * (1.6 - 0.4 * spike)))),
		"brutes": maxi(0, int(round(base_strength * 0.35 * spike))),
		"fliers": maxi(0, int(round(base_strength * 0.2 * spike)))
	}

func roll_local_anomalies():
	last_anomaly_tiles.clear()
	var base_risk: float = float(pressure_config.get("base_anomaly_risk", 0.01))
	var risk_multiplier: float = float(pressure_band.get("anomaly_risk_multiplier", 1.0))
	var risk: float = clampf(base_risk * risk_multiplier, 0.0, 0.95)

	var attempts := 3
	for _i in range(attempts):
		if randf() <= risk:
			var tile := Vector2i(
				randi_range(0, grid.GRID_WIDTH - 1),
				randi_range(0, grid.GRID_HEIGHT - 1)
			)
			last_anomaly_tiles.append(tile)

func get_terraform_metrics() -> Dictionary:
	return {
		"oxygen": oxygen,
		"heat": heat,
		"bio_energy": bio_energy
	}

func get_pressure_metrics() -> Dictionary:
	return {
		"value": planet_pressure,
		"band_id": pressure_band.get("id", "unknown"),
		"band_label": pressure_band.get("label", "Brak danych"),
		"alarm_color": pressure_band.get("alarm_color", "#EBCB4C"),
		"wave_frequency_multiplier": pressure_band.get("wave_frequency_multiplier", 1.0),
		"wave_comp_spike": pressure_band.get("wave_comp_spike", 1.0),
		"anomaly_risk_multiplier": pressure_band.get("anomaly_risk_multiplier", 1.0),
		"last_wave": last_wave_composition,
		"last_anomalies": last_anomaly_tiles.duplicate()
	}

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
