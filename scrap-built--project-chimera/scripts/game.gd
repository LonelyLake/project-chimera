extends Node

@onready var level_container = $LevelContainer

func change_level(level_path: String):
    # 1. Сначала загружаем ресурс
    var scene_resource = load(level_path)
    
    # 2. Проверяем, удалось ли загрузить
    if scene_resource == null:
        printerr("ОШИБКА: Не удалось загрузить сцену по пути: ", level_path)
        printerr("Проверь, существует ли файл и правильный ли путь!")
        return # Останавливаем функцию, чтобы не было краша
    
    # 3. Если всё ок, продолжаем
    for child in level_container.get_children():
        child.queue_free()
    
    await get_tree().process_frame 
    
    var new_level = scene_resource.instantiate()
    level_container.add_child(new_level)
