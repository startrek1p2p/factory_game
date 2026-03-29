extends Node2D

var grid := GridManager.new()
var simulation := Simulation.new(grid)

var hovered_tile: Vector2i = Vector2i(-1, -1)
var selected_building: int = GridManager.BuildingType.WALL
var selected_direction: int = GridManager.Direction.EAST
var build_mode_enabled: bool = false

var tick_timer: float = 0.0
var tick_interval: float = 0.3

const BASE_UI_MARGIN := 16.0
const MAX_PANEL_WIDTH := 320.0

const BUILDING_DATA := {
	GridManager.BuildingType.WALL: {
		"name": "Ściana",
		"kind": "obrona",
		"description": "Prosta przeszkoda blokująca przejazd i chroniąca kluczowe sektory.",
		"cost": {"Minerały": 4}
	},
	GridManager.BuildingType.MINE: {
		"name": "Kopalnia",
		"kind": "kopalnia",
		"description": "Wydobywa minerały i przekazuje je dalej przez logistykę.",
		"cost": {"Minerały": 6, "Energia": 2}
	},
	GridManager.BuildingType.CONVEYOR: {
		"name": "Przenośnik",
		"kind": "transport",
		"description": "Transportuje surowce do sąsiednich budynków zgodnie z kierunkiem.",
		"cost": {"Minerały": 2}
	},
	GridManager.BuildingType.STORAGE: {
		"name": "Magazyn",
		"kind": "magazyn",
		"description": "Przyjmuje i gromadzi dostarczone surowce.",
		"cost": {"Minerały": 8, "Energia": 1}
	}
}

@onready var renderer: WorldRenderer = $World/Renderer
<<<<<<< HEAD
@onready var hud: CanvasLayer = $HUD
=======
@onready var resources_panel: PanelContainer = $UI/TopRightMargin/ResourcesPanel
@onready var resources_value_label: Label = $UI/TopRightMargin/ResourcesPanel/ResourcesVBox/ResourcesValue
@onready var building_panel: PanelContainer = $UI/BottomRightMargin/SelectedBuildingPanel
@onready var building_name_label: Label = $UI/BottomRightMargin/SelectedBuildingPanel/BuildingVBox/BuildingName
@onready var building_kind_label: Label = $UI/BottomRightMargin/SelectedBuildingPanel/BuildingVBox/BuildingKind
@onready var building_description_label: Label = $UI/BottomRightMargin/SelectedBuildingPanel/BuildingVBox/BuildingDescription
@onready var building_cost_label: Label = $UI/BottomRightMargin/SelectedBuildingPanel/BuildingVBox/BuildingCost
>>>>>>> main

func _ready():
	renderer.grid = grid
	renderer.hovered_tile = hovered_tile
	renderer.selected_building = selected_building
	renderer.selected_direction = selected_direction
	update_hud()

	print("Start systemu budowania")
	update_ui_margins()
	refresh_resources_panel()
	refresh_selected_building_panel()
	queue_redraw()

func _process(delta):
	handle_build_selection()
	handle_simulation(delta)
	update_ui_margins()

	var mouse_pos = get_global_mouse_position()
	hovered_tile = grid.world_to_grid(mouse_pos)

	renderer.hovered_tile = hovered_tile
	renderer.selected_building = selected_building
	renderer.selected_direction = selected_direction
	renderer.queue_redraw()

func _input(event):
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE:
			get_tree().quit()
		if event.keycode == KEY_R:
			selected_direction = (selected_direction + 1) % 6
			print("selected_direction =", selected_direction)
			renderer.selected_direction = selected_direction
			renderer.queue_redraw()
		if event.keycode == KEY_0:
			build_mode_enabled = false
			refresh_selected_building_panel()

	if event is InputEventMouseButton and event.pressed:
		var mouse_pos = get_global_mouse_position()
		var tile = grid.world_to_grid(mouse_pos)

		if not grid.is_tile_in_bounds(tile):
			return

		if event.button_index == MOUSE_BUTTON_LEFT:
			if not build_mode_enabled:
				return
			grid.place_building(tile, selected_building, selected_direction)
			renderer.queue_redraw()

		elif event.button_index == MOUSE_BUTTON_RIGHT:
			grid.place_building(tile, GridManager.BuildingType.EMPTY)
			renderer.queue_redraw()

func handle_build_selection():
	var previous_selection := selected_building
	var previous_mode := build_mode_enabled

	if Input.is_key_pressed(KEY_1):
		selected_building = GridManager.BuildingType.WALL
		build_mode_enabled = true
	elif Input.is_key_pressed(KEY_2):
		selected_building = GridManager.BuildingType.MINE
		build_mode_enabled = true
	elif Input.is_key_pressed(KEY_3):
		selected_building = GridManager.BuildingType.CONVEYOR
		build_mode_enabled = true
	elif Input.is_key_pressed(KEY_4):
		selected_building = GridManager.BuildingType.STORAGE
		build_mode_enabled = true

	if previous_selection != selected_building or previous_mode != build_mode_enabled:
		refresh_selected_building_panel()

func handle_simulation(delta: float):
	tick_timer += delta

	if tick_timer >= tick_interval:
		tick_timer = 0.0
		simulation.tick()
<<<<<<< HEAD
		update_hud()
		print("Storage:", simulation.storage_count)

func update_hud():
	hud.update_metrics(simulation.get_terraform_metrics(), simulation.get_pressure_metrics())
=======
		refresh_resources_panel()
		print("Storage:", simulation.storage_count)

func refresh_resources_panel():
	var minerals := simulation.storage_count
	var energy := 0
	var biomass := 0

	resources_value_label.text = "Minerały: %d\nEnergia: %d\nBiomasa/Impuls: %d" % [minerals, energy, biomass]

func refresh_selected_building_panel():
	if not build_mode_enabled:
		building_name_label.text = "Brak wybranego budynku"
		building_kind_label.text = "Rodzaj: —"
		building_description_label.text = "Wybierz klawisz 1-4, aby wejść w tryb stawiania."
		building_cost_label.visible = false
		return

	var building_info: Dictionary = BUILDING_DATA.get(selected_building, {})
	var building_name: String = building_info.get("name", "Nieznany budynek")
	var building_kind: String = building_info.get("kind", "nieokreślony")
	var building_description: String = building_info.get("description", "Brak opisu.")
	var cost_data: Dictionary = building_info.get("cost", {})

	building_name_label.text = building_name
	building_kind_label.text = "Rodzaj: %s" % building_kind.capitalize()
	building_description_label.text = building_description

	if cost_data.is_empty():
		building_cost_label.visible = false
	else:
		building_cost_label.visible = true
		building_cost_label.text = "Koszt: %s" % format_cost_data(cost_data)

func format_cost_data(cost_data: Dictionary) -> String:
	var entries: Array[String] = []
	for resource_name in cost_data.keys():
		entries.append("%s %s" % [str(cost_data[resource_name]), resource_name])
	return ", ".join(entries)

func update_ui_margins():
	var viewport_size := get_viewport_rect().size
	var responsive_margin := maxf(BASE_UI_MARGIN, minf(viewport_size.x, viewport_size.y) * 0.02)

	$UI/TopRightMargin.offset_top = responsive_margin
	$UI/TopRightMargin.offset_right = -responsive_margin
	$UI/BottomRightMargin.offset_bottom = -responsive_margin
	$UI/BottomRightMargin.offset_right = -responsive_margin

	resources_panel.custom_minimum_size.x = minf(MAX_PANEL_WIDTH, viewport_size.x * 0.36)
	building_panel.custom_minimum_size.x = minf(MAX_PANEL_WIDTH, viewport_size.x * 0.36)
>>>>>>> main
