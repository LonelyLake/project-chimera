@tool
extends Area2D


@export var item_data: ItemData
const POPUP_SCENE = preload("res://scenes/ui/popup_label.tscn")

@onready var sprite = $Sprite2D


func _ready():
    if item_data and item_data.texture:
        sprite.texture = item_data.texture
        
        var tween = create_tween().set_loops()
        tween.tween_property($Sprite2D, "position:y", -2.0, 0.5).as_relative()
        tween.tween_property($Sprite2D, "position:y", 2.0, 0.5).as_relative()


func collect():
    if item_data == null:
        return

    print("Item picked up: ", item_data.item_name)

    if item_data is RobotPart or item_data is Consumable:
        GameManager.add_to_inventory(item_data)
    
    finalize_collection()
    

func finalize_collection():
    spawn_popup()
    queue_free()


func spawn_popup():
    var popup = POPUP_SCENE.instantiate()
    get_tree().current_scene.add_child(popup)
    
    popup.get_node("Label").text = "+ " + item_data.item_name
    
    var player = get_tree().get_first_node_in_group("player")
    if player:
        popup.global_position = player.global_position + Vector2(-20, -10)
    


func _on_body_entered(body: Node2D) -> void:
    if body.is_in_group("player") and item_data is Consumable:
        if item_data.auto_collect:
            var needs_hp = item_data.hp_restore > 0 and GameManager.player_hp < GameManager.player_max_hp
            var needs_energy = item_data.energy_restore > 0 and GameManager.player_energy < GameManager.player_max_energy
            
            if needs_hp or needs_energy:
                if needs_hp: 
                    GameManager.repair_player(item_data.hp_restore)
                if needs_energy: 
                    GameManager.restore_energy(item_data.energy_restore)
                
                finalize_collection()
                
