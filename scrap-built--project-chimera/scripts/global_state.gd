extends Node


var player_hp: int = 50
var player_max_hp: int = 50
var player_energy: int = 150
var player_max_energy: int = 150
var scrap_count: int = 0


var equipped_parts = {
	"head": null,
	"torso": null,
	"arms": null,
	"legs": null
}

var collected_parts = []


func _ready() -> void:
	equipped_parts["legs"] = load("res://resources/parts/light_legs.tres")


func add_scrap(amount: int):
	scrap_count += amount
	print("Scrap metal collected! Total: ", scrap_count)


func repair_player(amount: int):
	player_hp = min(player_hp + amount, player_max_hp)
	print("Robot repaired. HP: ", player_hp)
	

func get_total_speed(base_speed: float) -> float:
	var bonus = 0.0
	
	if equipped_parts["legs"] != null:
		bonus += equipped_parts["legs"].speed_bonus
		
	return base_speed + bonus
