extends Area2D

@onready var ui = $CanvasLayer/MinigameUI
@onready var play_area = $CanvasLayer/MinigameUI/Background/PlayArea
@onready var player_rect = $CanvasLayer/MinigameUI/Background/PlayArea/PlayerRect
@onready var status_label = $CanvasLayer/MinigameUI/Background/StatusLabel
@onready var time_label = $CanvasLayer/MinigameUI/Background/TimeLabel
@onready var sprite = $Sprite2D

var is_playing = false
var is_won = false

var time_left = 10.0
var player_pos_y = 50.0
var player_speed = 100.0

var obstacles = []
var obstacle_spawn_timer = 0.0

func _ready():
    ui.hide()

func collect():
    if not is_playing and not is_won:
        start_minigame()

func start_minigame():
    is_playing = true
    time_left = 10.0
    player_pos_y = 50.0
    player_rect.position.y = player_pos_y
    
    # Clear old obstacles
    for obs in obstacles:
        if is_instance_valid(obs):
            obs.queue_free()
    obstacles.clear()
    obstacle_spawn_timer = 0.0
    
    ui.show()
    status_label.text = "DODGE WITH [UP]/[DOWN]"
    get_tree().get_first_node_in_group("player").set_physics_process(false)

func _process(delta):
    if is_playing:
        time_left -= delta
        time_label.text = "HACKING: " + str(snapped(time_left, 0.1)) + "s"
        
        # Move player
        if Input.is_action_pressed("ui_up") or Input.is_action_pressed("move_up"):
            player_pos_y -= player_speed * delta
        if Input.is_action_pressed("ui_down") or Input.is_action_pressed("move_down"):
            player_pos_y += player_speed * delta
            
        player_pos_y = clamp(player_pos_y, 0, play_area.size.y - player_rect.size.y)
        player_rect.position.y = player_pos_y
        
        # Spawn obstacles
        obstacle_spawn_timer -= delta
        if obstacle_spawn_timer <= 0:
            spawn_obstacle()
            obstacle_spawn_timer = randf_range(0.4, 0.8)
            
        # Move obstacles and check collision
        var p_rect = Rect2(player_rect.position, player_rect.size)
        for i in range(obstacles.size() - 1, -1, -1):
            var obs = obstacles[i]
            if is_instance_valid(obs):
                obs.position.x -= 120.0 * delta
                
                var o_rect = Rect2(obs.position, obs.size)
                if p_rect.intersects(o_rect):
                    fail()
                    return
                    
                if obs.position.x < -20:
                    obs.queue_free()
                    obstacles.remove_at(i)
        
        if time_left <= 0:
            win()

func spawn_obstacle():
    var obs = ColorRect.new()
    obs.color = Color(1.0, 0.2, 0.2, 1.0)
    # Random size and pos
    var size_y = randf_range(15.0, 40.0)
    obs.size = Vector2(10, size_y)
    var pos_y = randf_range(0.0, play_area.size.y - size_y)
    obs.position = Vector2(play_area.size.x, pos_y)
    play_area.add_child(obs)
    obstacles.append(obs)

func _input(event):
    if is_playing:
        if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
            end_game()

func win():
    is_playing = false
    is_won = true
    status_label.text = "ACCESS GRANTED! KEY AQUIRED!"
    sprite.modulate = Color(0.2, 1.0, 0.2)
    
    GameManager.collect_level_key()
    var key_data = load("res://resources/consumable/key_item_data.tres")
    if key_data:
        GameManager.add_to_inventory(key_data)
        
    await get_tree().create_timer(1.5).timeout
    end_game()

func fail():
    is_playing = false
    status_label.text = "VIRUS DETECTED! RESTARTING..."
    await get_tree().create_timer(1.5).timeout
    start_minigame()

func end_game():
    is_playing = false
    ui.hide()
    GameManager.set_world_pause(false)
