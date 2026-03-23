extends Area2D

@export var scrap_amount: int = 5


func _ready():
	var tween = create_tween().set_loops()
	tween.tween_property($Sprite2D, "position:y", -2.0, 0.5).as_relative()
	tween.tween_property($Sprite2D, "position:y", 2.0, 0.5).as_relative()


func collect():
	GameManager.add_scrap(scrap_amount)
	
	spawn_popup()
	
	queue_free()


func spawn_popup():
	var popup_scene = load("res://scenes/ui/popup_label.tscn")
	if popup_scene:
		var popup = popup_scene.instantiate()
		
		popup.get_node("Label").text = "+" + str(scrap_amount) + " scrap"
		
		get_tree().current_scene.add_child(popup)
		
		var player = get_tree().get_first_node_in_group("player")
		if player:
			popup.global_position = player.global_position + Vector2(-20, -10)


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		collect()
