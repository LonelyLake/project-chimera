extends Area2D

@onready var ui = $CanvasLayer/MinigameUI
@onready var status_label = $CanvasLayer/MinigameUI/Background/StatusLabel
@onready var indicator = $CanvasLayer/MinigameUI/Background/Indicator

var is_playing = false
var state = "IDLE" # IDLE, WAITING, ACTIVE, RESULT
var wait_timer = 0.0
var start_time = 0.0
var reaction_time = 0.0

func _ready():
	ui.hide()

func collect():
	if not is_playing:
		start_game()

func start_game():
	is_playing = true
	state = "WAITING"
	ui.show()
	GameManager.set_world_pause(true)
	indicator.color = Color(0.2, 0.2, 0.2)
	status_label.text = "WAIT FOR SIGNAL..."
	
	# Losowy czas oczekiwania 2-5 sekund
	wait_timer = randf_range(2.0, 5.0)

func _process(delta):
	if state == "WAITING":
		wait_timer -= delta
		if wait_timer <= 0:
			trigger_signal()

func trigger_signal():
	state = "ACTIVE"
	indicator.color = Color.GREEN
	status_label.text = "NOW!!!"
	start_time = Time.get_ticks_msec()

func _input(event):
	if is_playing:
		if event is InputEventKey and event.pressed:
			if event.keycode == KEY_SPACE:
				handle_input()
			elif event.keycode == KEY_ESCAPE:
				end_game()

func handle_input():
	if state == "WAITING":
		fail("TOO EARLY!")
	elif state == "ACTIVE":
		reaction_time = (Time.get_ticks_msec() - start_time) / 1000.0
		if reaction_time <= 0.3:
			win()
		else:
			fail("TOO SLOW! (" + str(reaction_time) + "s)")

func win():
	state = "RESULT"
	indicator.color = Color.CYAN
	status_label.text = "EXCELLENT! " + str(reaction_time) + "s\n+40 SCRAP"
	GameManager.add_scrap(40)
	await get_tree().create_timer(2.0).timeout
	end_game()

func fail(reason):
	state = "RESULT"
	indicator.color = Color.RED
	status_label.text = reason + "\nTRY AGAIN"
	await get_tree().create_timer(2.0).timeout
	start_game()

func end_game():
	is_playing = false
	state = "IDLE"
	ui.hide()
	GameManager.set_world_pause(false)
