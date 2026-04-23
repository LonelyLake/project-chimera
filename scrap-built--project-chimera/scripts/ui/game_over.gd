extends CanvasLayer

func _ready():
    hide()
    %RestartButton.pressed.connect(_on_restart)

func _on_restart():
    get_tree().paused = false
    GameManager.player_hp = GameManager.player_max_hp
    GameManager.player_energy = GameManager.player_max_energy
    GameManager.scrap_count = 0
    get_tree().reload_current_scene()
    
    # Clear inventory
    GameManager.inventory.clear()
    GameManager.equipped_parts = {
        "head": GameManager.DEFAULT_HEAD,
        "torso": GameManager.DEFAULT_TORSO,
        "arms": GameManager.DEFAULT_ARMS,
        "wheel": GameManager.DEFAULT_WHEEL
    }
    GameManager.recalculate_stats()
