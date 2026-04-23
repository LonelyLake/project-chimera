extends Area2D

@onready var bubble = $CanvasLayer/ExitUI
var is_player_near = false

func _ready():
    bubble.hide()

func _on_body_entered(body):
    if body.is_in_group("player"):
        is_player_near = true
        bubble.show()

func _on_body_exited(body):
    if body.is_in_group("player"):
        is_player_near = false
        bubble.hide()

func _input(event):
    if is_player_near and bubble.visible:
        if event is InputEventKey and event.pressed:
            if event.keycode == KEY_Y:
                get_tree().quit()
            elif event.keycode == KEY_N:
                bubble.hide()
