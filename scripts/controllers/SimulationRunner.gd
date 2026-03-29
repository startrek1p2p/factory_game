class_name SimulationRunner
extends RefCounted

signal tick_completed()

var simulation
var tick_timer: float = 0.0
var tick_interval: float = 0.3

func _init(simulation_instance, interval: float = 0.3):
	simulation = simulation_instance
	tick_interval = interval

func process(delta: float) -> void:
	tick_timer += delta

	if tick_timer < tick_interval:
		return

	tick_timer = 0.0
	simulation.tick()
	tick_completed.emit()
