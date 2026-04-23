extends Area2D

@onready var ui = $CanvasLayer/MinigameUI
@onready var status_label = $CanvasLayer/MinigameUI/Background/StatusLabel
@onready var indicators = {
    "up": $CanvasLayer/MinigameUI/Background/Grid/Up,
    "down": $CanvasLayer/MinigameUI/Background/Grid/Down,
    "left": $CanvasLayer/MinigameUI/Background/Grid/Left,
    "right": $CanvasLayer/MinigameUI/Background/Grid/Right
}

var is_playing = false
var sequence = []
var player_sequence = []
var current_step = 0
var game_round = 1
var max_rounds = 3
var showing_sequence = false

func _ready():
    ui.hide()

func collect():
    if not is_playing:
        start_game()

func start_game():
    is_playing = true
    game_round = 1
    ui.show()
    GameManager.set_world_pause(true)
    next_round()

func next_round():
    showing_sequence = true
    player_sequence = []
    sequence = []
    var seq_length = 2 + game_round
    
    for i in range(seq_length):
        var dirs = ["up", "down", "left", "right"]
        sequence.append(dirs[randi() % 4])
    
    status_label.text = "WATCH: ROUND " + str(game_round) + "/" + str(max_rounds)
    
    await get_tree().create_timer(1.0).timeout
    
    for dir in sequence:
        highlight_indicator(dir)
        await get_tree().create_timer(0.6).timeout
        reset_indicators()
        await get_tree().create_timer(0.2).timeout
    
    showing_sequence = false
    status_label.text = "YOUR TURN!"

func highlight_indicator(dir):
    reset_indicators()
    indicators[dir].color = Color(1, 1, 1, 1) # White highlight

func reset_indicators():
    indicators["up"].color = Color(0.2, 0.2, 0.2, 1)
    indicators["down"].color = Color(0.2, 0.2, 0.2, 1)
    indicators["left"].color = Color(0.2, 0.2, 0.2, 1)
    indicators["right"].color = Color(0.2, 0.2, 0.2, 1)

func _input(event):
    if is_playing and not showing_sequence:
        if event is InputEventKey and event.pressed:
            var input_dir = ""
            if event.keycode == KEY_W or event.keycode == KEY_UP:
                input_dir = "up"
            elif event.keycode == KEY_S or event.keycode == KEY_DOWN:
                input_dir = "down"
            elif event.keycode == KEY_A or event.keycode == KEY_LEFT:
                input_dir = "left"
            elif event.keycode == KEY_D or event.keycode == KEY_RIGHT:
                input_dir = "right"
            elif event.keycode == KEY_ESCAPE:
                end_game()
                return
                
            if input_dir != "":
                check_input(input_dir)

func check_input(dir):
    highlight_indicator(dir)
    get_tree().create_timer(0.2).timeout.connect(reset_indicators)
    
    if dir == sequence[player_sequence.size()]:
        player_sequence.append(dir)
        if player_sequence.size() == sequence.size():
            if game_round >= max_rounds:
                win()
            else:
                game_round += 1
                status_label.text = "CORRECT!"
                await get_tree().create_timer(1.0).timeout
                next_round()
    else:
        fail()

func win():
    status_label.text = "MEMORY STABLE! +30 SCRAP"
    GameManager.add_scrap(30)
    await get_tree().create_timer(1.5).timeout
    end_game()

func fail():
    status_label.text = "SEQUENCE ERROR! TRY AGAIN"
    await get_tree().create_timer(1.5).timeout
    game_round = 1
    next_round()

func end_game():
    is_playing = false
    ui.hide()
    GameManager.set_world_pause(false)
