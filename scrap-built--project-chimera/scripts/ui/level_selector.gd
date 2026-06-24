extends CanvasLayer

signal level_selected(level_index)

@onready var preview_rect = $Control/Panel/Preview
@onready var level_label = $Control/Panel/LevelName
@export var level_container: Node2D

var current_level = 1
var max_levels = 3

# Symulacja tekstur dla poziomów (używamy różnych fragmentów z arkusza propsów)
var level_data = {
    1: {"name": "FACTORY", "region": Rect2(0, 0, 48, 48)},     # Pierwszy blok obiektów
    2: {"name": "CYBER SEWERS", "region": Rect2(48, 0, 48, 48)},       # Kolejny zestaw
    3: {"name": "TECH CITADEL", "region": Rect2(96, 0, 48, 48)}        # Trzeci zestaw
}

var level_paths = {
    1: "res://scenes/levels/factory.tscn",
    2: "res://scenes/levels/empty_level.tscn",
    3: "res://scenes/levels/empty_level.tscn",
}

func _ready():
    hide()
    update_display()

func open():
    show()
    current_level = 1
    update_display()
    GameManager.set_world_pause(true)

func close():
    hide()
    GameManager.set_world_pause(false)

func _input(event):
    if not visible: return
    
    if event.is_action_pressed("ui_left") or event.is_action_pressed("move_left"):
        change_level(-1)
    elif event.is_action_pressed("ui_right") or event.is_action_pressed("move_right"):
        change_level(1)
    elif event.is_action_pressed("ui_accept") or event.is_action_pressed("accept"):
        confirm_selection()
    elif event.is_action_pressed("ui_cancel"):
        close()

func change_level(dir):
    current_level = clampi(current_level + dir, 1, max_levels)
    update_display()

func update_display():
    var data = level_data[current_level]
    level_label.text = data["name"]
    var atlas = preview_rect.texture as AtlasTexture
    if atlas:
        atlas.region = data["region"]

func confirm_selection():
    if current_level != 1:
        print("Этот уровень заблокирован в демо-версии!")
        level_label.text = "LOCKED IN DEMO!"
        return
        
    level_selected.emit(current_level)
    
    var main_game_root = get_tree().current_scene
    var level_container = main_game_root.get_node_or_null("LevelContainer")
    
    if level_container:
        for child in level_container.get_children():
            child.queue_free()
            
        var new_level_scene = load(level_paths[current_level])
        if new_level_scene:
            var new_level_instance = new_level_scene.instantiate()
            level_container.add_child(new_level_instance)
            
    GameManager.set_world_pause(false)
    close()
