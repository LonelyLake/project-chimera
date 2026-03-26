class_name MeleeEnemy
extends Enemy

@onready var anim = $AnimatedSprite2D
@onready var detection_zone = $DetectionZone

var player = null


func _ready():
	detection_zone.body_entered.connect(_on_body_entered)
	detection_zone.body_exited.connect(_on_body_exited)


func _physics_process(_delta):
	if player != null:
		var direction = (player.global_position - global_position).normalized()
		velocity = direction * speed
		
		anim.play("move")
			
		if player.global_position.x > global_position.x:
			anim.flip_h = true
		else:
			anim.flip_h = false
			
	else:
		velocity = Vector2.ZERO
		anim.play("idle")
		
	move_and_slide()


func _on_body_entered(body):
	if body.is_in_group("player"):
		player = body


func _on_body_exited(body):
	if body.is_in_group("player"):
		player = null
