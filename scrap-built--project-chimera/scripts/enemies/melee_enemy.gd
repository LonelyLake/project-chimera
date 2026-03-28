class_name MeleeEnemy
extends Enemy

var is_attacking = false

@onready var anim = $AnimatedSprite2D
@onready var detection_zone = $DetectionZone
@onready var nav_agent = $NavigationAgent2D
@onready var attack_cooldown = $AttackCooldown
@onready var knockback_timer = $KnockbackTimer
@onready var attack_zone = $AttackZone


func _ready():
    detection_zone.body_entered.connect(on_player_entered)
    detection_zone.body_exited.connect(on_player_exited)
    
    anim.frame_changed.connect(_on_frame_changed)
    
    attack_cooldown.wait_time = 1.5
    knockback_timer.wait_time = 0.3
    knockback_timer.timeout.connect(_on_knockback_finished)
    
    attack_zone.monitoring = true


func _update_path(target: Vector2):
    nav_agent.target_position = target
    
    if not nav_agent.is_navigation_finished():
        var next_point = nav_agent.get_next_path_position()
        var direction = (next_point - global_position).normalized()
        velocity = direction * speed
        anim.flip_h = direction.x > 0
        anim.play("move")


func _state_idle():
    velocity = Vector2.ZERO
    anim.play("idle")


func _state_attack():
    velocity = Vector2.ZERO
    
    if is_attacking:
        return
    
    if player == null:
        change_state(State.SEARCH)
        return
    
    var dist = global_position.distance_to(player.global_position)
    if dist > attack_range * 1.2:
        change_state(State.CHASE)
        return
    
    if attack_cooldown.is_stopped():
        is_attacking = true
        anim.play("attack")
        attack_cooldown.start()

        await anim.animation_finished
        is_attacking = false
    else:
        anim.play("idle")
    
    
func _on_frame_changed():
    if anim.animation == "attack" and anim.frame == 2:
        if attack_zone.monitoring:
            _check_hit()


func _check_hit():
    var bodies = attack_zone.get_overlapping_bodies()
    for body in bodies:
        if body.is_in_group("player"):
            GameManager.take_damage(damage)
            body.apply_knockback(global_position)
            
            
func _state_knockback():
    velocity = knockback_direction * 150.0
    anim.play("hurt")


func _on_knockback_finished():
    change_state(State.CHASE)


func apply_knockback(from_position: Vector2, force: float = 150.0):
    knockback_direction = (global_position - from_position).normalized()
    change_state(State.KNOCKBACK)
    knockback_timer.start()  


func die():
    is_dying = true
    velocity = Vector2.ZERO
    GameManager.add_scrap(scrap_reward)
    $CollisionShape2D.set_deferred("disabled", true)
    attack_zone.monitoring = false
    detection_zone.monitoring = false
    
    var knockback = knockback_direction * 200.0
    velocity = knockback
    await get_tree().create_timer(0.15).timeout
    
    velocity = Vector2.ZERO
    anim.play("death")
    await anim.animation_finished
    queue_free()


func take_damage(amount: int):
    if is_dying:
        return
    hp -= amount
    if hp <= 0:
        is_dying = true
        die()
    else:
        anim.play("hurt")
