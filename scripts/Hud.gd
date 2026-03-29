extends CanvasLayer

@onready var oxygen_bar: ProgressBar = $PanelContainer/MarginContainer/VBox/OxygenRow/OxygenBar
@onready var heat_bar: ProgressBar = $PanelContainer/MarginContainer/VBox/HeatRow/HeatBar
@onready var bio_bar: ProgressBar = $PanelContainer/MarginContainer/VBox/BioRow/BioBar
@onready var pressure_bar: ProgressBar = $PanelContainer/MarginContainer/VBox/PressureRow/PressureBar
@onready var pressure_label: Label = $PanelContainer/MarginContainer/VBox/PressureRow/PressureLabel

func update_metrics(terraform_metrics: Dictionary, pressure_metrics: Dictionary):
	oxygen_bar.value = float(terraform_metrics.get("oxygen", 0.0))
	heat_bar.value = float(terraform_metrics.get("heat", 0.0))
	bio_bar.value = float(terraform_metrics.get("bio_energy", 0.0))

	pressure_bar.value = float(pressure_metrics.get("value", 0.0))
	var band_label: String = str(pressure_metrics.get("band_label", "Brak danych"))
	pressure_label.text = "Presja planetarna: %s" % band_label

	var color = Color(str(pressure_metrics.get("alarm_color", "#EBCB4C")))
	pressure_bar.modulate = color
	pressure_label.modulate = color
