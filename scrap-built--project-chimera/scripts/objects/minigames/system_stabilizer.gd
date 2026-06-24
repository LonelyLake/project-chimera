extends Area2D

@onready var ui = $CanvasLayer/MinigameUI
@onready var indicator = $CanvasLayer/MinigameUI/Background/ProgressBar/Indicator
@onready var status_label = $CanvasLayer/MinigameUI/Background/StatusLabel
@onready var time_label = $CanvasLayer/MinigameUI/Background/TimeLabel
@onready var sprite = $Sprite2D

var is_playing = false
var is_won = false

var time_left = 5.0
var indicator_pos = 0.0 # From -1.0 to 1.0 (0 is center)
var current_wind = 0.0
var wind_change_timer = 0.0
var player_force = 1.5

func _ready():
    ui.hide()

func collect():
    if not is_playing and not is_won:
        start_minigame()

func start_minigame():
    is_playing = true
    time_left = 5.0
    indicator_pos = 0.0
    current_wind = 0.0
    wind_change_timer = 0.0
    ui.show()
    status_label.text = "BALANCE WITH [LEFT]/[RIGHT]"
    _update_indicator_visual()
    get_tree().get_first_node_in_group("player").set_physics_process(false)

func _process(delta):
    if is_playing:
        time_left -= delta
        time_label.text = "STABILIZING: " + str(snapped(time_left, 0.1)) + "s"
        
        # Change wind every 0.5s to 1.5s
        wind_change_timer -= delta
        if wind_change_timer <= 0:
            wind_change_timer = randf_range(0.5, 1.5)
            current_wind = randf_range(-1.2, 1.2)
            
        # Apply wind
        indicator_pos += current_wind * delta
        
        # Apply player input
        if Input.is_action_pressed("ui_left") or Input.is_action_pressed("move_left"):
            indicator_pos -= player_force * delta
        if Input.is_action_pressed("ui_right") or Input.is_action_pressed("move_right"):
            indicator_pos += player_force * delta
            
        _update_indicator_visual()
        
        # Check fail/win
        if abs(indicator_pos) > 1.0:
            fail()
        elif time_left <= 0:
            win()

func _update_indicator_visual():
    # Map -1.0 .. 1.0 to X position within the bar (e.g. 0 to 160)
    var bar_width = 160.0
    var mapped_x = (indicator_pos + 1.0) / 2.0 * bar_width
    # Center the indicator on the mapped X
    indicator.position.x = mapped_x - indicator.size.x / 2.0

func _input(event):
    if is_playing:
        if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
            end_game()

func win():
    is_playing = false
    is_won = true
    status_label.text = "SYSTEM STABLE! KEY AQUIRED!"
    sprite.modulate = Color(0.2, 1.0, 0.2)
    
    GameManager.collect_level_key()
    var key_data = load("res://resources/consumable/key_item_data.tres")
    if key_data:
        GameManager.add_to_inventory(key_data)
        
    await get_tree().create_timer(1.5).timeout
    end_game()

func fail():
    is_playing = false
    status_label.text = "SYSTEM CRASHED! RESTARTING..."
    await get_tree().create_timer(1.5).timeout
    start_minigame()

func end_game():
    is_playing = false
    ui.hide()
    GameManager.set_world_pause(false)
