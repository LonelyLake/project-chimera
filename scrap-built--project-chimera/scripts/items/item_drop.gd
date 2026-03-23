@tool
extends Area2D

# We'll drag our .tres files here in the inspector (for example, heavy legs)
@export var item_data: RobotPart
const POPUP_SCENE = preload("res://scenes/ui/popup_label.tscn")

@onready var sprite = $Sprite2D


func _ready():
# If the data has been added and the part has an image, apply it to the sprite
	if item_data and item_data.texture:
		sprite.texture = item_data.texture

# The player will call this function when they press "E"
func collect():
	if item_data == null:
		return

	print("Item picked up: ", item_data.part_name)

	# For testing: if these are legs, equip them immediately
	if item_data.type == RobotPart.PartType.LEGS:
		GameManager.equipped_parts["legs"] = item_data
		print("New legs equipped!")
	
	var popup = POPUP_SCENE.instantiate()
	
	popup.get_node("Label").text = "+ " + item_data.part_name
	var player = get_tree().get_first_node_in_group("player")
	if player:
		get_tree().current_scene.add_child(popup)
		popup.global_position = player.global_position + Vector2(-20, -10)

	queue_free()
