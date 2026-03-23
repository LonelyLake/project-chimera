extends CanvasLayer

@onready var hp_bar = $PanelContainer/MarginContainer/HBoxContainer/VBoxContainer/GridContainer/ProgressBar
@onready var energy_bar = $PanelContainer/MarginContainer/HBoxContainer/VBoxContainer/GridContainer/ProgressBar
@onready var scrap_label = $PanelContainer/MarginContainer/HBoxContainer/ScrapLabel
@onready var location_label = $PanelContainer/MarginContainer/HBoxContainer/LocationLabel


func _ready() -> void:
	hp_bar.max_value = GameManager.player_max_hp
	energy_bar.max_value = GameManager.player_max_energy
	
	location_label.text = "LOCATION: THE HUB"


func _process(_delta: float) -> void:
	hp_bar.value = GameManager.player_hp
	energy_bar.value = GameManager.player_energy
	
	scrap_label.text = "SCRAP: " + str(GameManager.scrap_count)
