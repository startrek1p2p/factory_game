class_name InputController
extends RefCounted

const GridManagerScript = preload("res://scripts/GridManager.gd")

signal quit_requested
signal build_mode_changed(selected_building: int, build_mode_enabled: bool)
signal direction_changed(selected_direction: int)
signal build_requested(tile: Vector2i, building_type: int, direction: int)
signal clear_requested(tile: Vector2i)

const ACTION_BUILD_WALL := "build_wall"
const ACTION_BUILD_MINE := "build_mine"
const ACTION_BUILD_CONVEYOR := "build_conveyor"
const ACTION_BUILD_STORAGE := "build_storage"
const ACTION_BUILD_SOLAR_PANEL := "build_solar_panel"
const ACTION_BUILD_ENERGY_NODE := "build_energy_node"
const ACTION_BUILD_DISABLE := "build_disable"
const ACTION_ROTATE_BUILDING := "rotate_building"
const ACTION_QUIT := "quit_game"

var hovered_tile: Vector2i = Vector2i(-1, -1)
var selected_building: int = GridManagerScript.BuildingType.WALL
var selected_direction: int = GridManagerScript.Direction.EAST
var build_mode_enabled: bool = false

func setup_default_actions() -> void:
	_register_action_if_missing(ACTION_BUILD_WALL, KEY_1)
	_register_action_if_missing(ACTION_BUILD_MINE, KEY_2)
	_register_action_if_missing(ACTION_BUILD_CONVEYOR, KEY_3)
	_register_action_if_missing(ACTION_BUILD_STORAGE, KEY_4)
	_register_action_if_missing(ACTION_BUILD_SOLAR_PANEL, KEY_5)
	_register_action_if_missing(ACTION_BUILD_ENERGY_NODE, KEY_6)
	_register_action_if_missing(ACTION_BUILD_DISABLE, KEY_0)
	_register_action_if_missing(ACTION_ROTATE_BUILDING, KEY_R)
	_register_action_if_missing(ACTION_QUIT, KEY_ESCAPE)

func update_hovered_tile(mouse_position: Vector2, grid) -> void:
	hovered_tile = grid.world_to_grid(mouse_position)

func handle_selection_actions() -> void:
	var previous_selection := selected_building
	var previous_mode := build_mode_enabled

	if Input.is_action_pressed(ACTION_BUILD_WALL):
		selected_building = GridManagerScript.BuildingType.WALL
		build_mode_enabled = true
	elif Input.is_action_pressed(ACTION_BUILD_MINE):
		selected_building = GridManagerScript.BuildingType.MINE
		build_mode_enabled = true
	elif Input.is_action_pressed(ACTION_BUILD_CONVEYOR):
		selected_building = GridManagerScript.BuildingType.CONVEYOR
		build_mode_enabled = true
	elif Input.is_action_pressed(ACTION_BUILD_STORAGE):
		selected_building = GridManagerScript.BuildingType.STORAGE
		build_mode_enabled = true
	elif Input.is_action_pressed(ACTION_BUILD_SOLAR_PANEL):
		selected_building = GridManagerScript.BuildingType.SOLAR_PANEL
		build_mode_enabled = true
	elif Input.is_action_pressed(ACTION_BUILD_ENERGY_NODE):
		selected_building = GridManagerScript.BuildingType.ENERGY_NODE
		build_mode_enabled = true

	if previous_selection != selected_building or previous_mode != build_mode_enabled:
		build_mode_changed.emit(selected_building, build_mode_enabled)

func handle_input_event(event: InputEvent, mouse_position: Vector2, grid) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.is_action_pressed(ACTION_QUIT):
			quit_requested.emit()
		if event.is_action_pressed(ACTION_ROTATE_BUILDING):
			_rotate_direction(1)
		if event.is_action_pressed(ACTION_BUILD_DISABLE):
			build_mode_enabled = false
			build_mode_changed.emit(selected_building, build_mode_enabled)

	if event is InputEventMouseButton and event.pressed:
		if build_mode_enabled and event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_rotate_direction(1)
			return
		elif build_mode_enabled and event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_rotate_direction(-1)
			return

		var tile = grid.world_to_grid(mouse_position)
		if not grid.is_tile_in_bounds(tile):
			return

		if event.button_index == MOUSE_BUTTON_LEFT:
			if not build_mode_enabled:
				return
			build_requested.emit(tile, selected_building, selected_direction)
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			clear_requested.emit(tile)

func _rotate_direction(step: int) -> void:
	selected_direction = posmod(selected_direction + step, 6)
	direction_changed.emit(selected_direction)

func _register_action_if_missing(action_name: String, keycode: Key) -> void:
	if not InputMap.has_action(action_name):
		InputMap.add_action(action_name)

	for input_event in InputMap.action_get_events(action_name):
		if input_event is InputEventKey and input_event.keycode == keycode:
			return

	var new_event := InputEventKey.new()
	new_event.keycode = keycode
	InputMap.action_add_event(action_name, new_event)
