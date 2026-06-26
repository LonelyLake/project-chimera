extends Area2D

@export_file("*.tscn") var destination_scene: String 

func interact():
    # Получаем доступ к Game и вызываем метод смены
    var game = get_tree().root.get_node("Game") # Или другой способ получения ссылки
    game.change_level("res://scenes/levels/hub.tscn")
