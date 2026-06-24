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
    # Безопасное управление окончанием анимаций через сигнал движка:
    anim.animation_finished.connect(_on_animation_finished)
    
    attack_cooldown.wait_time = 1.5
    knockback_timer.wait_time = 0.3
    knockback_timer.timeout.connect(_on_knockback_finished)
    
    attack_zone.monitoring = true

# Перехватываем смену состояний: если врага прервали во время атаки, сбрасываем флаг флаг атаки
func change_state(new_state: State):
    if current_state == State.ATTACK and new_state != State.ATTACK:
        is_attacking = false
    super.change_state(new_state)

func _update_path(target: Vector2):
    nav_agent.target_position = target
    
    if not nav_agent.is_navigation_finished():
        var next_point = nav_agent.get_next_path_position()
        var direction = (next_point - global_position).normalized()
        
        var separation = Vector2.ZERO
        var neighbors = $DetectionZone.get_overlapping_bodies()
        for body in neighbors:
            if body.is_in_group("enemy") and body != self:
                var diff = global_position - body.global_position
                if diff.length() < 24:
                    separation += diff.normalized()
        
        var final_direction = (direction + separation * 0.8).normalized()
        velocity = final_direction * speed
        anim.flip_h = velocity.x > 0
        
        # Запускаем бег только если не заняты атакой или получением урона
        if current_state == State.CHASE and anim.animation != "move":
            anim.play("move")

func _state_idle():
    velocity = Vector2.ZERO
    if anim.animation != "idle" and not is_attacking:
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
    else:
        if anim.animation != "idle":
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
            if body.has_method("apply_knockback"):
                body.apply_knockback(global_position)

func _state_knockback():
    velocity = knockback_direction * 150.0
    # Проверка, чтобы не перезапускать анимацию боли каждый кадр:
    if anim.animation != "hurt":
        anim.play("hurt")

func _on_knockback_finished():
    change_state(State.CHASE)

func apply_knockback(from_position: Vector2, force: float = 150.0):
    if is_dying: return
    knockback_direction = (global_position - from_position).normalized()
    change_state(State.KNOCKBACK)
    knockback_timer.start()  

func _on_animation_finished():
    # Вместо забагованных await используем безопасный обработчик сигналов
    if anim.animation == "attack":
        is_attacking = false
        if current_state == State.ATTACK:
            anim.play("idle")
    elif anim.animation == "death":
        queue_free()

func die():
    if is_dying: return
    is_dying = true
    velocity = Vector2.ZERO
    GameManager.add_scrap(scrap_reward)
    
    # Безопасное отключение физики
    $CollisionShape2D.set_deferred("disabled", true)
    attack_zone.set_deferred("monitoring", false)
    detection_zone.set_deferred("monitoring", false)
    
    anim.play("death")

func take_damage(amount: int):
    if is_dying:
        return
    hp -= amount
    if hp <= 0:
        die()
    else:
        # Если выжил — включаем отбрасывание, оно само включит анимацию боли
        apply_knockback(player.global_position if player else global_position)
