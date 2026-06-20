extends Area2D

@onready var ui = $CanvasLayer/MinigameUI
@onready var slider = $CanvasLayer/MinigameUI/Background/Slider
@onready var target_zone = $CanvasLayer/MinigameUI/Background/TargetZone
@onready var status_label = $CanvasLayer/MinigameUI/Background/StatusLabel

var is_playing = false
var slider_pos = 0.0
var slider_speed = 2.0
var slider_direction = 1
var success_count = 0
var required_successes = 3


func _ready():
    ui.hide()


func collect():
    if not is_playing:
        start_minigame()


func start_minigame():
    is_playing = true
    success_count = 0
    slider_speed = 2.0
    ui.show()
    status_label.text = "STABILIZE THE CORE: 0/" + str(required_successes)
    # Update instructions to show ESC
    $CanvasLayer/MinigameUI/Background/InstructionLabel.text = "PRESS [SPACE] TO STABILIZE / [ESC] TO EXIT"
    get_tree().get_first_node_in_group("player").set_physics_process(false)


func _process(delta):
    if is_playing:
        slider_pos += slider_speed * slider_direction * delta * 100
        
        if slider_pos > 200 or slider_pos < 0:
            slider_direction *= -1
            
        slider.position.x = slider_pos


func _input(event):
    if is_playing:
        if event is InputEventKey and event.pressed:
            if event.keycode == KEY_SPACE:
                check_timing()
            elif event.keycode == KEY_ESCAPE:
                end_game()


func check_timing():
    # Sprawdzamy pozycję X suwaka względem zielonej strefy
    # slider_pos to nasza zmienna, która kontroluje suwak
    var target_start = target_zone.position.x
    var target_end = target_start + target_zone.size.x
    
    if slider_pos >= target_start and slider_pos <= target_end:
        success_count += 1
        slider_speed += 1.5 # Przyspieszamy!
        status_label.text = "SUCCESS! " + str(success_count) + "/" + str(required_successes)
        
        if success_count >= required_successes:
            win()
    else:
        fail()


func win():
    is_playing = false
    status_label.text = "CORE STABILIZED! +25 SCRAP"
    GameManager.add_scrap(25)
    await get_tree().create_timer(1.5).timeout
    end_game()


func fail():
    is_playing = false
    status_label.text = "SYSTEM CRITICAL! RESETTING..."
    await get_tree().create_timer(1.5).timeout
    success_count = 0
    slider_speed = 2.0
    is_playing = true # Restartujemy rundę


func end_game():
    is_playing = false
    ui.hide()
    GameManager.set_world_pause(false)
