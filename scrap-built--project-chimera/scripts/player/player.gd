extends CharacterBody2D


@export var speed: float = 100.0
var last_direction = "down"
var is_attacking = false
var is_knockback = false
var is_invincible = false
var is_dashing = false
var is_dead = false
var is_dialogue_active: bool = false
var knockback_velocity = Vector2.ZERO

var dash_speed = 400.0
var dash_duration = 0.2
var energy_cost = 30
var energy_regen_rate = 6.0 

var regen_delay_time: float = 1.2
var regen_timer: float = 0.0

var dash_cooldown_max: float = 1.5
var dash_cooldown_timer: float = 0.0

@onready var anim = $AnimatedSprite2D
@onready var hit_zone = $HitZone
@onready var interaction_zone = $InteractionZone


func _ready():
    hit_zone.body_entered.connect(_on_hit_zone_entered)
    $DashHitZone.body_entered.connect(_on_dash_hit_zone_entered)
    GameManager.player_died.connect(_on_player_died)


func _physics_process(delta: float) -> void:
    if is_dead:
        if is_knockback:
            _process_knockback()
        move_and_slide()
        return
    
    if is_dialogue_active:
        velocity = Vector2.ZERO # Останавливаем движение
        anim.play("idle_down") # Ставим в позу покоя
        return
    
    if dash_cooldown_timer > 0:
        dash_cooldown_timer -= delta
    
    if regen_timer > 0.0:
        regen_timer -= delta
    elif GameManager.player_energy < GameManager.player_max_energy:
        GameManager.restore_energy(energy_regen_rate * delta)
    
    if is_knockback:
        _process_knockback()
        move_and_slide()
        return
    
    if is_dashing:  
        move_and_slide()
        return
    
    var direction := Input.get_vector("move_left", "move_right", "move_up", "move_down")
    var current_speed = speed + GameManager.player_speed_bonus
    velocity = direction * current_speed
    move_and_slide()
    update_animation(direction)


func update_animation(dir: Vector2):
    if is_attacking:
        return
    
    if dir == Vector2.ZERO:
        if last_direction == "left":
            anim.flip_h = true
            anim.play("idle_right")
        else:
            anim.flip_h = false
            anim.play("idle_" + last_direction)
    else:
        if abs(dir.x)  >= abs(dir.y):
            if dir.x < 0:
                last_direction = "left"
                anim.flip_h = true
            else:
                last_direction = "right"
                anim.flip_h = false
            anim.play("walk_right")
        elif dir.y > 0:
            last_direction = "down"
            anim.play("walk_down")
            anim.flip_h = false
        elif dir.y < 0:
            last_direction = "up"
            anim.play("walk_up")
            anim.flip_h = false
            
    _update_hit_zone()


func apply_knockback(from_position: Vector2):
    if GameManager.player_invincible:
        return
        
    is_knockback = true
    knockback_velocity = (global_position - from_position).normalized() * 200.0
    
    if last_direction == "left":
        anim.flip_h = true
        anim.play("hurt_right")
    else:
        anim.flip_h = false
        anim.play("hurt_" + last_direction)
        
    await get_tree().process_frame
    
    GameManager.player_invincible = true
    
    await get_tree().create_timer(0.3).timeout
    
    if not GameManager.player_hp <= 0:
        anim.modulate.a = 1.0
    GameManager.player_invincible = false


func _process_knockback():
    velocity = knockback_velocity
    knockback_velocity = knockback_velocity.lerp(Vector2.ZERO, 0.2)
    if knockback_velocity.length() < 5:
        is_knockback = false


func _perform_attack():
    is_attacking = true
    if last_direction == "left":
        anim.flip_h = true
        anim.play("attack_right")
    else:
        anim.flip_h = false
        anim.play("attack_" + last_direction)
    hit_zone.monitoring = true
    await anim.animation_finished
    hit_zone.monitoring = false
    is_attacking = false
    

func _perform_dash():
    if dash_cooldown_timer > 0 or GameManager.player_energy < energy_cost:
        return
        
    dash_cooldown_timer = dash_cooldown_max # Активируем перезарядку
    
    anim.modulate = Color(1.0, 0.0, 0.184, 1.0)
    
    match last_direction:
        "right":
            $DashHitZone.position = Vector2(20, 0)
            $DashHitZone.rotation = 0
            anim.flip_h = false
        "left":
            $DashHitZone.position = Vector2(-20, 0)
            $DashHitZone.rotation = 0
            anim.flip_h = true
        "up":
            $DashHitZone.position = Vector2(0, -20)
            $DashHitZone.rotation = deg_to_rad(90)
        "down":
            $DashHitZone.position = Vector2(0, 20)
            $DashHitZone.rotation = deg_to_rad(90) 
    
    GameManager.player_energy -= energy_cost
    GameManager.energy_changed.emit(GameManager.player_energy)
    
    regen_timer = regen_delay_time
    
    is_attacking = true
    $DashHitZone.monitoring = true
    
    is_dashing = true
    var dash_direction = _get_direction_vector()
    velocity = dash_direction * dash_speed

    if last_direction == "left":
        anim.flip_h = true
        anim.play("attack_right")
    else:
        anim.play("attack_" + last_direction)

    await get_tree().create_timer(dash_duration).timeout
    
    anim.modulate = Color.WHITE
    is_dashing = false
    $DashHitZone.monitoring = false
    is_attacking = false


func _on_hit_zone_entered(body):
    if body.is_in_group("enemy"):
        body.take_damage(_get_attack_damage())
        body.apply_knockback(global_position)


func _get_attack_damage() -> int:
    var bonus = 0
    if GameManager.equipped_parts["arms"] != null:
        bonus = GameManager.equipped_parts["arms"].attack_bonus
    return 10 + bonus


func _unhandled_input(event: InputEvent) -> void:
    if is_dialogue_active:
        return
    
    if event.is_action_pressed("attack") and not is_attacking:
        _perform_attack()
        
    if event.is_action_pressed("special") and not is_attacking and dash_cooldown_timer <= 0:
        _perform_dash()
        
    if event.is_action_pressed("interact"):
        var areas = interaction_zone.get_overlapping_areas()
        
        # Перебираем все объекты в зоне взаимодействия
        for item in areas:
            # Приоритет отдаем диалогам/терминалам (interact)
            if item.has_method("interact"):
                item.interact()
                return # Выходим из функции, чтобы не активировать лишнее
            
            # Если это не NPC, проверяем, можно ли это собрать (collect)
            if item.has_method("collect"):
                item.collect()
                return # Выходим после подбора
    
    if event.is_action_pressed("use_health"):
        GameManager.use_consumable_by_type("hp")
        
    if event.is_action_pressed("use_energy"):
        GameManager.use_consumable_by_type("energy")


func _update_hit_zone():
    match last_direction:
        "right": hit_zone.position = Vector2(12, 0)
        "left": hit_zone.position = Vector2(-12, 0)
        "down": hit_zone.position = Vector2(0, 12)
        "up": hit_zone.position = Vector2(0, -12)


func _get_direction_vector() -> Vector2:
    match last_direction:
        "right": return Vector2.RIGHT
        "left": return Vector2.LEFT
        "up": return Vector2.UP
        "down": return Vector2.DOWN
    return Vector2.DOWN
    
    
func _on_dash_hit_zone_entered(body):
    if body.is_in_group("enemy"):
        body.apply_knockback(global_position)
        body.take_damage(_get_attack_damage() * 2)


func _on_player_died():
    is_dead = true
    var tween = create_tween()
    tween.tween_property(anim, "modulate:a", 0.0, 0.8)
    await get_tree().create_timer(0.8).timeout
    var game_over = get_tree().root.find_child("GameOver", true, false)
    if game_over:
        game_over.show()
    get_tree().paused = true
