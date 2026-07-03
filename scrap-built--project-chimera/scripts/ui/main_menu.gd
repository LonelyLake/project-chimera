extends Control

@onready var settings_panel = $SettingsPanel
@onready var menu_buttons = $VBoxContainer

func _ready():
    settings_panel.hide()
    menu_buttons.show()

func _on_start_button_pressed():
    print("Starting game...")
    get_tree().change_scene_to_file("res://scenes/game.tscn") 

func _on_settings_button_pressed():
    settings_panel.show()
    menu_buttons.hide()

func _on_close_settings_button_pressed():
    settings_panel.hide()
    menu_buttons.show()


func _on_fullscreen_check_toggled(toggled_on: bool) -> void:
    if toggled_on:
        DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN)
    else:
        DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)


func _on_volume_slider_value_changed(value: float) -> void:
    var bus_index = AudioServer.get_bus_index("Master")
    
    AudioServer.set_bus_volume_db(bus_index, linear_to_db(value))


func _on_quit_button_pressed() -> void:
    get_tree().quit()
