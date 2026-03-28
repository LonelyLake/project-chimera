extends CanvasLayer

@onready var hp_bar = $PanelContainer/MarginContainer/HBoxContainer/VBoxContainer/GridContainer/HealthBar
@onready var energy_bar = $PanelContainer/MarginContainer/HBoxContainer/VBoxContainer/GridContainer/EnergyBar
@onready var scrap_label = $PanelContainer/MarginContainer/HBoxContainer/ScrapLabel
@onready var location_label = $PanelContainer/MarginContainer/HBoxContainer/LocationLabel
@onready var inventory_list = $InventoryPanel/MarginContainer/VBoxContainer/ItemList


func _ready() -> void:
	hp_bar.max_value = GameManager.player_max_hp
	energy_bar.max_value = GameManager.player_max_energy
	location_label.text = "LOCATION: THE HUB"
	
	hp_bar.value = GameManager.player_hp
	energy_bar.value = GameManager.player_energy
	scrap_label.text = "SCRAP: " + str(GameManager.scrap_count)
	
	update_inventory()
	
	GameManager.hp_changed.connect(func(v): hp_bar.value = v)
	GameManager.max_hp_changed.connect(func(v): hp_bar.max_value = v)
	GameManager.energy_changed.connect(func(v): energy_bar.value = v)
	GameManager.scrap_changed.connect(func(v): scrap_label.text = "SCRAP: " + str(v))
	GameManager.inventory_changed.connect(update_inventory)


func update_inventory():
	# Clear existing items
	for child in inventory_list.get_children():
		child.queue_free()
	
	# Add current items from inventory
	for item in GameManager.inventory:
		var label = Label.new()
		label.text = "- " + item.item_name
		label.add_theme_font_size_override("font_size", 10)
		inventory_list.add_child(label)
