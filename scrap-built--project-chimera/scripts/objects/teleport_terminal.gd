extends Area2D

@export_file("*.tscn") var destination_scene: String 


func interact():
    if GameManager.keys_collected < 3:
        print("Access Denied: Missing Factory Security Keys!")
        
        Dialogic.start("terminal_locked")
        
        return
        
    var game = get_tree().root.get_node("Game")
    game.change_level("res://scenes/levels/hub.tscn")
