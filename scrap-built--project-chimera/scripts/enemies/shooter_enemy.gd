class_name ShooterEnemy
extends Enemy

@onready var anim = $AnimatedSprite2D
@onready var detection_zone = $DetectionZone
@onready var attack_cooldown = $AttackCooldown
@onready var knockback_timer = $KnockbackTimer
@onready var bullet_spawn = $BulletSpawn

const BULLET_SCENE = preload("res://scenes/enemies/bullet.tscn")

var is_shooting = false


func _ready():
    detection_zone.body_entered.connect(on_player_entered)
    detection_zone.body_exited.connect(on_player_exited)
    attack_cooldown.wait_time = 2.0
    knockback_timer.wait_time = 0.3
    knockback_timer.timeout.connect(_on_knockback_finished)


func _get_initial_state() -> State:
    return State.ATTACK


func _state_idle():
    velocity = Vector2.ZERO
    anim.play("idle")


func _state_attack():
    velocity = Vector2.ZERO
    
    if player != null:
        if player.global_position.x > global_position.x:
            anim.flip_h = true
            bullet_spawn.position.x = abs(bullet_spawn.position.x)  # справа
        else:
            anim.flip_h = false
            bullet_spawn.position.x = -abs(bullet_spawn.position.x)
    
    if is_shooting:
        return
    
    if player == null:
        change_state(State.IDLE)
        return
    
    if attack_cooldown.is_stopped():
        is_shooting = true
        last_known_position = player.global_position
        anim.play("attack")
        attack_cooldown.start()
        await anim.animation_finished
        _shoot()
        is_shooting = false


func _shoot():
    var target = player.global_position if player != null else last_known_position
    if target == Vector2.ZERO:
        return
    var bullet = BULLET_SCENE.instantiate()
    get_tree().current_scene.add_child(bullet)
    bullet.global_position = bullet_spawn.global_position
    bullet.direction = (target - bullet_spawn.global_position).normalized()
    bullet.rotation = bullet.direction.angle()
    
    
func _state_knockback():
    velocity = knockback_direction * 150.0
    anim.play("hurt")

func _on_knockback_finished():
    change_state(State.ATTACK if player != null else State.IDLE)

func apply_knockback(from_position: Vector2, force: float = 150.0):
    if is_dying:
        return
    knockback_direction = (global_position - from_position).normalized()
    change_state(State.KNOCKBACK)
    knockback_timer.start()

func take_damage(amount: int):
    if is_dying:
        return
    hp -= amount
    if hp <= 0:
        is_dying = true
        anim.play("hurt")
        velocity = knockback_direction * 200.0  # ← отлёт во время hurt
        await anim.animation_finished
        die()
    else:
        anim.play("hurt")

func die():
    is_dying = true
    GameManager.add_scrap(scrap_reward)
    $CollisionShape2D.set_deferred("disabled", true)
    detection_zone.monitoring = false
    anim.play("death")
    await anim.animation_finished
    queue_free()


func on_player_exited(body):
    if body.is_in_group("player"):
        player = null
        if not is_shooting:
            change_state(State.IDLE)
