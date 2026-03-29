extends Node2D

var grid := GridManager.new()
var simulation := Simulation.new(grid)

var hovered_tile: Vector2i = Vector2i(-1, -1)
var selected_building: int = GridManager.BuildingType.WALL
var selected_direction: int = GridManager.Direction.EAST

var tick_timer: float = 0.0
var tick_interval: float = 0.3

@onready var renderer: WorldRenderer = $World/Renderer

func _ready():
	renderer.grid = grid
	renderer.hovered_tile = hovered_tile
	renderer.selected_building = selected_building
	renderer.selected_direction = selected_direction

	print("Start systemu budowania")
	queue_redraw()

func _process(delta):
	if Input.is_action_just_pressed("ui_cancel"):
		get_tree().quit()

	handle_build_selection()
	handle_simulation(delta)

	var mouse_pos = get_global_mouse_position()
	hovered_tile = grid.world_to_grid(mouse_pos)

	renderer.hovered_tile = hovered_tile
	renderer.selected_building = selected_building
	renderer.selected_direction = selected_direction
	renderer.queue_redraw()

func _input(event):
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_R:
			selected_direction = (selected_direction + 1) % 6
			print("selected_direction =", selected_direction)
			renderer.selected_direction = selected_direction
			renderer.queue_redraw()

	if event is InputEventMouseButton and event.pressed:
		var mouse_pos = get_global_mouse_position()
		var tile = grid.world_to_grid(mouse_pos)

		if not grid.is_tile_in_bounds(tile):
			return

		if event.button_index == MOUSE_BUTTON_LEFT:
			grid.place_building(tile, selected_building, selected_direction)
			renderer.queue_redraw()

		elif event.button_index == MOUSE_BUTTON_RIGHT:
			grid.place_building(tile, GridManager.BuildingType.EMPTY)
			renderer.queue_redraw()

func handle_build_selection():
	if Input.is_key_pressed(KEY_1):
		selected_building = GridManager.BuildingType.WALL
	if Input.is_key_pressed(KEY_2):
		selected_building = GridManager.BuildingType.MINE
	if Input.is_key_pressed(KEY_3):
		selected_building = GridManager.BuildingType.CONVEYOR
	if Input.is_key_pressed(KEY_4):
		selected_building = GridManager.BuildingType.STORAGE

func handle_simulation(delta: float):
	tick_timer += delta

	if tick_timer >= tick_interval:
		tick_timer = 0.0
		simulation.tick()
		print("Storage:", simulation.storage_count)
