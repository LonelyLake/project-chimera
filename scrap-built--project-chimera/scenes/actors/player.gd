extends CharacterBody2D


@export var speed: float = 100.0

@onready var anim = $AnimatedSprite2D
var last_direction = "down"

@onready var interaction_zone = $InteractionZone


func _physics_process(_delta: float) -> void:
	var direction := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	
	var current_speed = GameManager.get_total_speed(speed)
	velocity = direction * current_speed
	move_and_slide()
	
	update_animation(direction)


func update_animation(dir: Vector2):
	if dir == Vector2.ZERO:
		anim.play("idle_" + last_direction)
	else:
		if abs(dir.x) > abs(dir.y):
			last_direction = "right"
			anim.play("walk_right")
			anim.flip_h = dir.x < 0
		elif dir.y > 0:
			last_direction = "down"
			anim.play("walk_down")
			anim.flip_h = false
		elif dir.y < 0:
			last_direction = "up"
			anim.play("walk_up")
			anim.flip_h = false


func _unhandled_input(event: InputEvent) -> void:
	# Check if the player pressed the interaction button
	if event.is_action_pressed("interact"):

		# Get a list of all Area2Ds that currently overlap with our zone
		var areas = interaction_zone.get_overlapping_areas()

		if areas.size() > 0:
			# Take the first item within the radius
			var item = areas[0]

			# Check if this object has a collect function
			if item.has_method("collect"):
				item.collect()
