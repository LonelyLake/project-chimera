extends Area2D

func _ready():
    var tween = create_tween().set_loops()
    tween.tween_property($Sprite2D, "position:y", -2.0, 0.5).as_relative()
    tween.tween_property($Sprite2D, "position:y", 2.0, 0.5).as_relative()


func collect():
    GameManager.collect_key()
    var key_data = load("res://resources/consumable/key_item_data.tres")
    if key_data:
        GameManager.add_to_inventory(key_data)
    spawn_popup()
    queue_free()


func spawn_popup():
    var popup_scene = load("res://scenes/ui/popup_label.tscn")
    if popup_scene:
        var popup = popup_scene.instantiate()
        get_tree().current_scene.add_child(popup)
        
        var label = popup.get_node_or_null("Label")
        if label:
            label.text = "Key collected!"
        
        var player = get_tree().get_first_node_in_group("player")
        if player:
            popup.global_position = player.global_position + Vector2(-20, -10)
