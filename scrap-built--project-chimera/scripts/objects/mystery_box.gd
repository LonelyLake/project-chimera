extends Area2D

enum BoxType { COMMON, RARE, EPIC }

@export var type: BoxType = BoxType.COMMON
@onready var ui_container = $CanvasLayer/MysteryBoxUI
@onready var message_label = $CanvasLayer/MysteryBoxUI/Panel/Label
@onready var panel = $CanvasLayer/MysteryBoxUI/Panel

var is_waiting_for_input: bool = false
var has_been_opened: bool = false


func _ready():
	ui_container.hide()
	# Ustawiamy kolor ramki w zależności od typu (opcjonalnie w kodzie)
	update_box_visuals()


func update_box_visuals():
	var style_box = panel.get_theme_stylebox("panel").duplicate()
	match type:
		BoxType.COMMON:
			style_box.border_color = Color(0.7, 0.7, 0.7) # Szary
		BoxType.RARE:
			style_box.border_color = Color(0.2, 0.5, 1.0) # Niebieski
		BoxType.EPIC:
			style_box.border_color = Color(0.8, 0.2, 1.0) # Fioletowy
	panel.add_theme_stylebox_override("panel", style_box)


func get_required_keys() -> int:
	match type:
		BoxType.COMMON: return 1
		BoxType.RARE: return 2
		BoxType.EPIC: return 3
	return 1


func collect():
	if has_been_opened: return
	
	var needed = get_required_keys()
	var current_keys = 0
	for item in GameManager.inventory:
		if item.item_name == "Rusty Key":
			current_keys += 1
			
	if current_keys >= needed:
		start_mystery_choice()
	else:
		spawn_popup("Need " + str(needed) + " keys!")


func start_mystery_choice():
	is_waiting_for_input = true
	ui_container.show()
	var type_name = BoxType.keys()[type].capitalize()
	message_label.text = type_name + " Mystery Box\nChoose prize: 1, 2, 3\n[ESC] to cancel"
	GameManager.set_world_pause(true)


func _input(event):
	if is_waiting_for_input:
		if event is InputEventKey and event.pressed:
			if event.keycode == KEY_1: consume_and_reward(1)
			elif event.keycode == KEY_2: consume_and_reward(2)
			elif event.keycode == KEY_3: consume_and_reward(3)
			elif event.keycode == KEY_ESCAPE: cancel_choice()


func cancel_choice():
	is_waiting_for_input = false
	ui_container.hide()
	GameManager.set_world_pause(false)


func consume_and_reward(choice: int):
	is_waiting_for_input = false
	has_been_opened = true
	
	var needed = get_required_keys()
	for i in range(needed):
		GameManager.remove_from_inventory("Rusty Key")
	
	# Zmiana tekstury na otwartą
	var atlas = $Sprite2D.texture as AtlasTexture
	if atlas: atlas.region = Rect2(272, 128, 16, 16)
	
	give_reward(choice)


func give_reward(choice: int):
	var reward_text = ""
	match type:
		BoxType.COMMON:
			match choice:
				1: 
					reward_text = "Won 30 Scrap!"
					GameManager.add_scrap(30)
				2:
					reward_text = "Won 10 Energy!"
					GameManager.restore_energy(10)
				3:
					reward_text = "Won 5 HP!"
					GameManager.repair_player(5)
		BoxType.RARE:
			match choice:
				1:
					reward_text = "Won 100 Scrap!"
					GameManager.add_scrap(100)
				2:
					reward_text = "Won Laser Gun!"
					GameManager.add_to_inventory(load("res://resources/consumable/laser_gun.tres"))
				3:
					reward_text = "Won 25 HP!"
					GameManager.repair_player(25)
		BoxType.EPIC:
			match choice:
				1:
					reward_text = "MATRIX FOUND!\n+ 500 Scrap Secured"
					GameManager.add_scrap(500)
				2:
					reward_text = "MATRIX FOUND!\n+ Heavy Wheels Installed"
					GameManager.add_to_inventory(load("res://resources/parts/heavy_wheel.tres"))
				3:
					reward_text = "MATRIX FOUND!\n+ Core Fully Repaired"
					GameManager.repair_player(100)
	
	message_label.text = reward_text
	await get_tree().create_timer(3.0).timeout
	ui_container.hide()
	
	if type == BoxType.EPIC:
		var player = get_tree().get_first_node_in_group("player")
		if player:
			player.is_dialogue_active = true
		
		if not Dialogic.timeline_ended.is_connected(_on_victory_dialogue_ended):
			Dialogic.timeline_ended.connect(_on_victory_dialogue_ended)
		
		Dialogic.start("game_ending")
	else:
		GameManager.set_world_pause(false)


func _on_victory_dialogue_ended():
	if Dialogic.timeline_ended.is_connected(_on_victory_dialogue_ended):
		Dialogic.timeline_ended.disconnect(_on_victory_dialogue_ended)
	
	var player = get_tree().get_first_node_in_group("player")
	if player:
		player.is_dialogue_active = false
		
	GameManager.set_world_pause(false)
	get_tree().paused = false
	
	get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")


func spawn_popup(text: String):
	var popup_scene = load("res://scenes/ui/popup_label.tscn")
	if popup_scene:
		var popup = popup_scene.instantiate()
		get_tree().current_scene.add_child(popup)
		popup.get_node("Label").text = text
		var player = get_tree().get_first_node_in_group("player")
		if player: popup.global_position = player.global_position + Vector2(-20, -10)
