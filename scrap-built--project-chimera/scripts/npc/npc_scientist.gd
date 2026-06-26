extends Area2D

var is_talking: bool = false

func interact() -> void:
    if is_talking:
        return
    
    # Ищем игрока в группе "player" (убедись, что твой игрок добавлен в эту группу!)
    var player = get_tree().get_first_node_in_group("player")
    if player:
        player.is_dialogue_active = true # Замораживаем игрока
        
    is_talking = true
    Dialogic.start("scientist_talk")
    
    if not Dialogic.timeline_ended.is_connected(_on_dialog_ended):
        Dialogic.timeline_ended.connect(_on_dialog_ended)

func _on_dialog_ended() -> void: 
    is_talking = false
    
    # Размораживаем игрока
    var player = get_tree().get_first_node_in_group("player")
    if player:
        player.is_dialogue_active = false
        print("Игрок разморожен") # Добавь это для проверки
        
    if Dialogic.timeline_ended.is_connected(_on_dialog_ended):
        Dialogic.timeline_ended.disconnect(_on_dialog_ended)
