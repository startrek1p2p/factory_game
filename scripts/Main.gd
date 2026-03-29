extends Node2D

const GridManagerScript = preload("res://scripts/GridManager.gd")
const SimulationScript = preload("res://scripts/Simulation.gd")
const InputControllerScript = preload("res://scripts/controllers/InputController.gd")
const UIControllerScript = preload("res://scripts/controllers/UIController.gd")
const SimulationRunnerScript = preload("res://scripts/controllers/SimulationRunner.gd")

var grid = GridManagerScript.new()
var simulation = SimulationScript.new(grid)
var input_controller = InputControllerScript.new()
var ui_controller = UIControllerScript.new()
var simulation_runner = SimulationRunnerScript.new(simulation)

@onready var renderer = $World/Renderer

func _ready() -> void:
	renderer.grid = grid
	input_controller.setup_default_actions()
	ui_controller.setup(self)

	input_controller.build_mode_changed.connect(_on_build_mode_changed)
	input_controller.direction_changed.connect(_on_direction_changed)
	input_controller.build_requested.connect(_on_build_requested)
	input_controller.clear_requested.connect(_on_clear_requested)
	input_controller.quit_requested.connect(_on_quit_requested)
	simulation_runner.tick_completed.connect(_on_simulation_tick_completed)

	print("Start systemu budowania")
	_sync_renderer_state()
	ui_controller.update_ui_margins(get_viewport_rect().size)
	ui_controller.refresh_resources_panel(simulation.economy_state, simulation.get_power_debug_stats())
	ui_controller.refresh_selected_building_panel(input_controller.selected_building, input_controller.build_mode_enabled)
	renderer.queue_redraw()

func _process(delta: float) -> void:
	input_controller.handle_selection_actions()
	simulation_runner.process(delta)
	ui_controller.update_ui_margins(get_viewport_rect().size)
	ui_controller.update_status_message()

	var mouse_pos := get_global_mouse_position()
	input_controller.update_hovered_tile(mouse_pos, grid)
	_sync_renderer_state()
	renderer.queue_redraw()

func _input(event: InputEvent) -> void:
	input_controller.handle_input_event(event, get_global_mouse_position(), grid)

func _on_build_mode_changed(_selected_building: int, _build_mode_enabled: bool) -> void:
	ui_controller.refresh_selected_building_panel(input_controller.selected_building, input_controller.build_mode_enabled)
	renderer.queue_redraw()

func _on_direction_changed(selected_direction: int) -> void:
	print("selected_direction =", selected_direction)
	renderer.selected_direction = selected_direction
	renderer.queue_redraw()

func _on_build_requested(tile: Vector2i, building_type: int, direction: int) -> void:
	var building_data: Dictionary = UIControllerScript.BUILDING_DATA.get(building_type, {})
	var cost: Dictionary = building_data.get("cost", {})

	if not simulation.economy_state.can_afford(cost):
		ui_controller.show_status_message("Za mało zasobów na ten budynek.")
		return

	simulation.economy_state.spend(cost)
	grid.place_building(tile, building_type, direction)
	ui_controller.refresh_resources_panel(simulation.economy_state, simulation.get_power_debug_stats())
	renderer.queue_redraw()

func _on_clear_requested(tile: Vector2i) -> void:
	grid.place_building(tile, GridManagerScript.BuildingType.EMPTY)
	renderer.queue_redraw()

func _on_quit_requested() -> void:
	get_tree().quit()

func _on_simulation_tick_completed() -> void:
	ui_controller.refresh_resources_panel(simulation.economy_state, simulation.get_power_debug_stats())
	print("Zasoby:", simulation.economy_state.resources)

func _sync_renderer_state() -> void:
	renderer.hovered_tile = input_controller.hovered_tile
	renderer.selected_building = input_controller.selected_building
	renderer.selected_direction = input_controller.selected_direction
