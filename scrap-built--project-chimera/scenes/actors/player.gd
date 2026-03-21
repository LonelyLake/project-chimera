extends CharacterBody2D

@export var speed: float = 200.0

@onready var anim = $AnimatedSprite2D


func _physics_process(_delta: float) -> void:
	var direction := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	
	velocity = direction * speed
	move_and_slide()
	
	update_animation(direction)
	

func update_animation(dir: Vector2):
	if dir == Vector2.ZERO:
		anim.play("idle_down")
	else:
		if abs(dir.x) > abs(dir.y): # Ruch poziomy jest silniejszy
			anim.play("walk_right")
			
			# KLUCZOWY MOMENT:
			if dir.x < 0:
				anim.flip_h = true  # Odbij w lewo
			else:
				anim.flip_h = false # Patrz w prawo (domyślnie)
				
		elif dir.y > 0:
			anim.play("walk_down")
			anim.flip_h = false
		elif dir.y < 0:
			anim.play("walk_up")
			anim.flip_h = false 
