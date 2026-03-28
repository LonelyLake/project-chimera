extends CanvasLayer


func _ready():
    %ItemList.item_activated.connect(_on_item_activated)
    
    hide()
    refresh()
    
func _unhandled_input(event):
    if event.is_action_pressed("inventory"):
        if visible:
            hide()
            get_tree().paused = false
        else:
            refresh()
            show()
            get_tree().paused = true


func _on_item_activated(index: int):
    var item = GameManager.inventory[index]
    if item is RobotPart:
        GameManager.equip_part(item)
        GameManager.inventory.erase(item)
        refresh()
    elif item is Consumable:
        if item.hp_restore > 0:
            GameManager.repair_player(item.hp_restore)
        if item.energy_restore > 0:
            GameManager.restore_energy(item.energy_restore)
        GameManager.inventory.erase(item)
        refresh()


func refresh():
    # Equipment slots
    %HeadSlot.text = _part_name("head")
    %TorsoSlot.text = _part_name("torso")
    %ArmsSlot.text = _part_name("arms")
    %LegsSlot.text = _part_name("wheel")
    
    # Scrap
    %ScrapLabel.text = "SCRAP: " + str(GameManager.scrap_count)
    
    # Inventory list
    %ItemList.clear()
    for item in GameManager.inventory:
        %ItemList.add_item(item.item_name)
        
    %StatsLabel.text = "HP: %d/%d     ENERGY: %d/%d" % [
        GameManager.player_hp,
        GameManager.player_max_hp,
        GameManager.player_energy,
        GameManager.player_max_energy
    ]


func _part_name(slot: String) -> String:
    var part = GameManager.equipped_parts[slot]
    return part.item_name if part != null else "— empty —"
