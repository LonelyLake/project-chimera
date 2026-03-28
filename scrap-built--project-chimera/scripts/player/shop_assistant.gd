extends CharacterBody2D

@onready var shop_ui_scene = preload("res://scenes/ui/shop_ui.tscn")
var shop_ui = null
var player_in_range = false

func _ready():
	# Instancjonujemy UI sklepu
	shop_ui = shop_ui_scene.instantiate()
	add_child(shop_ui)

func _input(event):
	if player_in_range:
		if event is InputEventKey and event.pressed and event.keycode == KEY_S:
			if not shop_ui.visible:
				shop_ui.open()
			else:
				shop_ui.close()

func _on_interaction_area_body_entered(body):
	if body.is_in_group("player"):
		player_in_range = true

func _on_interaction_area_body_exited(body):
	if body.is_in_group("player"):
		player_in_range = false
		if shop_ui.visible:
			shop_ui.close()
