extends Area2D

@onready var selector_scene = preload("res://scenes/ui/level_selector.tscn")
@onready var portal_ui = $CanvasLayer/PortalUI
var selector = null
var player_in_range = false

func _ready():
    selector = selector_scene.instantiate()
    add_child(selector)

func _on_body_entered(body):
    if body.is_in_group("player"):
        player_in_range = true
        portal_ui.show()

func _on_body_exited(body):
    if body.is_in_group("player"):
        player_in_range = false
        portal_ui.hide()
        if selector.visible:
            selector.close()

@export var required_keys: int = 0

func _input(event):
    if player_in_range and not selector.visible:
        if event is InputEventKey and event.pressed and event.keycode == KEY_ENTER:
            if required_keys > 0 and GameManager.keys_collected < required_keys:
                var missing = required_keys - GameManager.keys_collected
                spawn_prompt("NEED " + str(missing) + " MORE KEYS!")
            else:
                selector.open()

func spawn_prompt(text):
    # Możemy użyć istniejącego systemu popupów jeśli istnieje, 
    # lub po prostu wypisać w konsoli/użyć prostego Labela
    print(text)
