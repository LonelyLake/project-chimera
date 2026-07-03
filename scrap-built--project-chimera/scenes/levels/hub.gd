extends Node2D


func _ready() -> void:
    if not GameManager.intro_played:
        GameManager.intro_played = true
        
        var player = get_tree().get_first_node_in_group("player")
        if player:
            player.is_dialogue_active = true
        
        if not Dialogic.timeline_ended.is_connected(_on_intro_ended):
            Dialogic.timeline_ended.connect(_on_intro_ended)
            
        Dialogic.start("game_intro")
    else:
        print("Player returned to Hub. Intro skipped.")


func _on_intro_ended() -> void:
    var player = get_tree().get_first_node_in_group("player")
    if player:
        player.is_dialogue_active = false
        print("Intro finished, player free to move!")
        
    if Dialogic.timeline_ended.is_connected(_on_intro_ended):
        Dialogic.timeline_ended.disconnect(_on_intro_ended)
