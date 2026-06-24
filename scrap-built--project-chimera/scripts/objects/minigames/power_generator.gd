extends Area2D

@onready var ui = $CanvasLayer/MinigameUI
@onready var progress_bar = $CanvasLayer/MinigameUI/Background/ProgressBar
@onready var status_label = $CanvasLayer/MinigameUI/Background/StatusLabel
@onready var time_label = $CanvasLayer/MinigameUI/Background/TimeLabel
@onready var sprite = $Sprite2D

var is_playing = false
var is_won = false
var progress = 0.0
var max_progress = 100.0
var time_left = 0.0
var max_time = 4.0
var decay_rate = 15.0 # how fast progress drops
var click_power = 8.0 # progress per click

func _ready():
    ui.hide()

func collect():
    if not is_playing and not is_won:
        start_minigame()

func start_minigame():
    is_playing = true
    progress = 0.0
    time_left = max_time
    ui.show()
    status_label.text = "MASH [SPACE] TO GENERATE POWER!"
    time_label.text = "TIME: " + str(snapped(time_left, 0.1))
    progress_bar.value = progress
    get_tree().get_first_node_in_group("player").set_physics_process(false)

func _process(delta):
    if is_playing:
        time_left -= delta
        time_label.text = "TIME: " + str(snapped(time_left, 0.1))
        
        progress -= decay_rate * delta
        progress = clamp(progress, 0, max_progress)
        progress_bar.value = progress
        
        if progress >= max_progress:
            win()
        elif time_left <= 0:
            fail()

func _input(event):
    if is_playing:
        if event is InputEventKey and event.pressed:
            if event.keycode == KEY_SPACE:
                progress += click_power
            elif event.keycode == KEY_ESCAPE:
                end_game()

func win():
    is_playing = false
    is_won = true
    status_label.text = "POWER RESTORED! KEY AQUIRED!"
    sprite.modulate = Color(0.2, 1.0, 0.2) # Turn green
    
    GameManager.collect_level_key()
    var key_data = load("res://resources/consumable/key_item_data.tres")
    if key_data:
        GameManager.add_to_inventory(key_data)
        
    await get_tree().create_timer(1.5).timeout
    end_game()

func fail():
    is_playing = false
    status_label.text = "FAILED! TRY AGAIN."
    await get_tree().create_timer(1.5).timeout
    start_minigame()

func end_game():
    is_playing = false
    ui.hide()
    GameManager.set_world_pause(false)
