class_name UIController
extends RefCounted

const GridManagerScript = preload("res://scripts/GridManager.gd")

const BASE_UI_MARGIN := 16.0
const MAX_PANEL_WIDTH := 320.0

const BUILDING_DATA := {
	GridManagerScript.BuildingType.WALL: {
		"name": "Ściana",
		"kind": "obrona",
		"description": "Prosta przeszkoda blokująca przejazd i chroniąca kluczowe sektory.",
		"cost": {"Minerały": 4}
	},
	GridManagerScript.BuildingType.MINE: {
		"name": "Kopalnia",
		"kind": "kopalnia",
		"description": "Wydobywa minerały i przekazuje je dalej przez logistykę.",
		"cost": {"Minerały": 6, "Energia": 2}
	},
	GridManagerScript.BuildingType.CONVEYOR: {
		"name": "Przenośnik",
		"kind": "transport",
		"description": "Transportuje surowce do sąsiednich budynków zgodnie z kierunkiem.",
		"cost": {"Minerały": 2}
	},
	GridManagerScript.BuildingType.STORAGE: {
		"name": "Magazyn",
		"kind": "magazyn",
		"description": "Przyjmuje i gromadzi dostarczone surowce.",
		"cost": {"Minerały": 8, "Energia": 1}
	},
	GridManagerScript.BuildingType.SOLAR_PANEL: {
		"name": "Panel słoneczny",
		"kind": "energia",
		"description": "Zapewnia stałą moc dla infrastruktury wydobywczej.",
		"cost": {"Minerały": 5, "Biomasa": 1}
	}
}

var top_right_margin: MarginContainer
var bottom_right_margin: MarginContainer
var resources_panel: PanelContainer
var resources_value_label: Label
var building_panel: PanelContainer
var building_name_label: Label
var building_kind_label: Label
var building_description_label: Label
var building_cost_label: Label
var status_label: Label
var status_clear_at_seconds: float = 0.0

func setup(main_node: Node) -> void:
	top_right_margin = main_node.get_node("UI/TopRightMargin")
	bottom_right_margin = main_node.get_node("UI/BottomRightMargin")
	resources_panel = main_node.get_node("UI/TopRightMargin/ResourcesPanel")
	resources_value_label = main_node.get_node("UI/TopRightMargin/ResourcesPanel/ResourcesVBox/ResourcesValue")
	building_panel = main_node.get_node("UI/BottomRightMargin/SelectedBuildingPanel")
	building_name_label = main_node.get_node("UI/BottomRightMargin/SelectedBuildingPanel/BuildingVBox/BuildingName")
	building_kind_label = main_node.get_node("UI/BottomRightMargin/SelectedBuildingPanel/BuildingVBox/BuildingKind")
	building_description_label = main_node.get_node("UI/BottomRightMargin/SelectedBuildingPanel/BuildingVBox/BuildingDescription")
	building_cost_label = main_node.get_node("UI/BottomRightMargin/SelectedBuildingPanel/BuildingVBox/BuildingCost")
	status_label = main_node.get_node("UI/TopRightMargin/ResourcesPanel/ResourcesVBox/StatusLabel")

func refresh_resources_panel(economy_state) -> void:
	var resources: Dictionary = economy_state.resources
	resources_value_label.text = "Minerały: %d\nEnergia: %d\nBiomasa: %d" % [
		int(resources.get("Minerały", 0)),
		int(resources.get("Energia", 0)),
		int(resources.get("Biomasa", 0))
	]
	resources_value_label.text += "\nTytan: %d" % int(resources.get("Tytan", 0))

func refresh_selected_building_panel(selected_building: int, build_mode_enabled: bool) -> void:
	if not build_mode_enabled:
		building_name_label.text = "Brak wybranego budynku"
		building_kind_label.text = "Rodzaj: —"
		building_description_label.text = "Wybierz klawisz 1-5, aby wejść w tryb stawiania."
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
		building_cost_label.text = "Koszt: %s" % _format_cost_data(cost_data)

func update_ui_margins(viewport_size: Vector2) -> void:
	var responsive_margin := maxf(BASE_UI_MARGIN, minf(viewport_size.x, viewport_size.y) * 0.02)

	top_right_margin.offset_top = responsive_margin
	top_right_margin.offset_right = -responsive_margin
	bottom_right_margin.offset_bottom = -responsive_margin
	bottom_right_margin.offset_right = -responsive_margin

	resources_panel.custom_minimum_size.x = minf(MAX_PANEL_WIDTH, viewport_size.x * 0.36)
	building_panel.custom_minimum_size.x = minf(MAX_PANEL_WIDTH, viewport_size.x * 0.36)

func _format_cost_data(cost_data: Dictionary) -> String:
	var entries: Array[String] = []
	for resource_name in cost_data.keys():
		entries.append("%s %s" % [str(cost_data[resource_name]), resource_name])
	return ", ".join(entries)

func show_status_message(message: String, duration_seconds: float = 1.8) -> void:
	status_label.text = message
	status_label.visible = true
	status_clear_at_seconds = Time.get_ticks_msec() / 1000.0 + duration_seconds

func update_status_message() -> void:
	if not status_label.visible:
		return

	var now_seconds := Time.get_ticks_msec() / 1000.0
	if now_seconds >= status_clear_at_seconds:
		status_label.visible = false
