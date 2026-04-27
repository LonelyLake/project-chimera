extends Area2D

var direction = Vector2.ZERO
var speed = 150.0
var damage = 10

func _ready():
    body_entered.connect(_on_body_entered)

func _physics_process(delta):
    position += direction * speed * delta

func _on_body_entered(body):
    if body.is_in_group("player"):
        GameManager.take_damage(damage)
        body.apply_knockback(global_position)
    
    set_physics_process(false)
    $AnimatedSprite2D.play("impact")
    await $AnimatedSprite2D.animation_finished
    queue_free()
    
