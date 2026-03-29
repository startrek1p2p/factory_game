class_name EconomyState
extends RefCounted

const RESOURCE_MINERALS := "Minerały"
const RESOURCE_ENERGY := "Energia"
const RESOURCE_BIOMASS := "Biomasa"

var resources: Dictionary = {
	RESOURCE_MINERALS: 100,
	RESOURCE_ENERGY: 100,
	RESOURCE_BIOMASS: 100
}

func can_afford(cost: Dictionary) -> bool:
	for resource_name in cost.keys():
		var required_amount: int = int(cost[resource_name])
		var current_amount: int = int(resources.get(resource_name, 0))
		if current_amount < required_amount:
			return false
	return true

func spend(cost: Dictionary) -> void:
	for resource_name in cost.keys():
		var required_amount: int = int(cost[resource_name])
		var current_amount: int = int(resources.get(resource_name, 0))
		resources[resource_name] = current_amount - required_amount

func add_resource(resource_name: String, amount: int) -> void:
	var current_amount: int = int(resources.get(resource_name, 0))
	resources[resource_name] = current_amount + amount
