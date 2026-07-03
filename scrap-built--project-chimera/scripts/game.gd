extends Node

@onready var level_container = $LevelContainer

func change_level(level_path: String):
    GameManager.player_invincible = true
    
    var scene_resource = load(level_path)
    
    if scene_resource == null:
        printerr("ОШИБКА: Не удалось загрузить сцену по пути: ", level_path)
        GameManager.player_invincible = false
        return
        
    # 1. Fading screen
    var fade_layer = CanvasLayer.new()
    fade_layer.layer = 128
    var fade_rect = ColorRect.new()
    fade_rect.color = Color(0, 0, 0, 0)
    fade_rect.size = Vector2(5000, 5000)
    fade_layer.add_child(fade_rect)
    add_child(fade_layer)

    # 2. Fade Out — 0.3 sec
    var tween_out = create_tween()
    tween_out.tween_property(fade_rect, "color:a", 1.0, 0.3)
    await tween_out.finished

    # 3. Change location
    for child in level_container.get_children():
        child.queue_free()
    
    await get_tree().process_frame 
    
    var new_level = scene_resource.instantiate()
    level_container.add_child(new_level)
    
    var ui_node = get_node_or_null("UI")
    if ui_node and ui_node.has_method("update_location"):
        ui_node.update_location(level_path)

    await get_tree().create_timer(0.1).timeout

    # 4. Fade In — 0.3 sec
    var tween_in = create_tween()
    tween_in.tween_property(fade_rect, "color:a", 0.0, 0.3)
    await tween_in.finished

    fade_layer.queue_free()
    
    GameManager.player_invincible = false
