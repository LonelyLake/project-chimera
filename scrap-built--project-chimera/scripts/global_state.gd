extends Node


var player_hp: int = 50
var player_max_hp: int = 50
var player_energy: int = 150
var player_max_energy: int = 150
var scrap_count: int = 0


var equipped_parts = {
	"head": "Mk.1 Blue",
	"torso": "Standard Frame",
	"arms": "Basic Grippers",
	"legs": "Standard Struts"
}

var collected_parts = []


func add_scrap(amount: int):
	scrap_count += amount
	print("Scrap metal collected! Total: ", scrap_count)


func repair_player(amount: int):
	player_hp = min(player_hp + amount, player_max_hp)
	print("Robot repaired. HP: ", player_hp)
