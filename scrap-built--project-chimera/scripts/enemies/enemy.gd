class_name Enemy
extends CharacterBody2D


@export var hp: int = 30
@export var speed: float = 60.0
@export var damage: int = 10
@export var scrap_reward: int = 5


func take_damage(amount: int):
	hp -= amount
	if hp <= 0:
		die()


func die():
	GameManager.add_scrap(scrap_reward)
	queue_free()
