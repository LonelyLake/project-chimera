class_name PatrolEnemy
extends Enemy

@onready var anim = $AnimatedSprite2D
@onready var vision_cone = $VisionCone
@onready var attack_zone = $AttackZone
@onready var nav_agent = $NavigationAgent2D
@onready var attack_cooldown = $AttackCooldown
@onready var knockback_timer = $KnockbackTimer
@onready var los_ray = $LosRay # ← Наш новый луч

@export var waypoints: Array[NodePath] = []
@export var patrol_speed: float = 40.0
@export var aggro_radius: float = 150.0

var waypoint_nodes: Array = []
var current_waypoint_index = 0

var lose_player_timer: float = 0.0
var lose_player_delay: float = 0.5
var search_timer: float = 0.0
var search_duration: float = 3.0

# Храним ссылку на игрока, ТОЛЬКО если он физически внутри конуса-триггера
var player_in_cone_zone: Node2D = null 


func _ready():
    await get_tree().physics_frame
    
    vision_cone.body_entered.connect(_on_vision_cone_entered)
    vision_cone.body_exited.connect(_on_vision_cone_exited)
    knockback_timer.wait_time = 0.3
    knockback_timer.timeout.connect(_on_knockback_finished)
    attack_cooldown.wait_time = 1.0
    
    # Автоматически выключаем луч, чтобы он не ел ресурсы зря, будем включать руками
    los_ray.enabled = false 
    
    # Load waypoints
    for path in waypoints:
        waypoint_nodes.append(get_node(path))


func _get_initial_state() -> State:
    return State.IDLE


# Функция проверки прямой видимости (проверяет стены)
func _can_see_player(target_player: Node2D) -> bool:
    if target_player == null:
        return false
        
    # Направляем луч прямо в центр игрока
    los_ray.target_position = los_ray.to_local(target_player.global_position)
    los_ray.force_raycast_update() # Обновляем физику луча прямо в этот микрокадр
    
    if los_ray.is_colliding():
        var collider = los_ray.get_collider()
        # Если первый объект, в который врезался луч — это игрок, значит стен между ними нет!
        if collider.is_in_group("player"):
            return true
    return false


func _state_idle():
    if waypoint_nodes.size() > 0:
        change_state(State.PATROL)
    velocity = Vector2.ZERO
    anim.play("idle")


func _state_patrol():
    if waypoint_nodes.is_empty():
        change_state(State.IDLE)
        return
        
    # ПРОВЕРКА СТЕЛСА: Если игрок в зоне и луч его видит (нет стен) — агримся
    if _can_see_player(player_in_cone_zone):
        player = player_in_cone_zone
        change_state(State.CHASE)
        return
        
    var target = waypoint_nodes[current_waypoint_index].global_position
    _move_toward(target, patrol_speed)
    if velocity.length() > 5:
        vision_cone.rotation = velocity.angle()
        los_ray.rotation = velocity.angle() # Поворачиваем луч вслед за взглядом
        
    if global_position.distance_to(target) < 10:
        current_waypoint_index = (current_waypoint_index + 1) % waypoint_nodes.size()


func _state_chase():
    # Проверяем, видит ли враг игрока прямо СЕЙЧАС (не спрятался ли тот за стену)
    var vision_blocked = not _can_see_player(player)
    
    # Если игрок убежал далеко ИЛИ спрятался за стену
    if player == null or global_position.distance_to(player.global_position) > aggro_radius or vision_blocked:
        velocity = Vector2.ZERO
        anim.play("idle")
        lose_player_timer += get_physics_process_delta_time()
        
        if lose_player_timer >= lose_player_delay:
            lose_player_timer = 0.0
            player = null
            change_state(State.SEARCH)
        return
    
    # Если всё ок, продолжаем погоню
    lose_player_timer = 0.0
    last_known_position = player.global_position
    has_last_known_position = true
    
    anim.flip_h = (player.global_position.x > global_position.x)
    
    var to_player = (player.global_position - global_position).normalized()
    vision_cone.rotation = to_player.angle()
    los_ray.rotation = to_player.angle()
    
    nav_agent.target_position = player.global_position
    if not nav_agent.is_navigation_finished():
        var next_point = nav_agent.get_next_path_position()
        velocity = (next_point - global_position).normalized() * speed
        anim.play("move")
        
    if attack_cooldown.is_stopped():
        for body in attack_zone.get_overlapping_bodies():
            if body.is_in_group("player"):
                GameManager.take_damage(damage)
                body.apply_knockback(global_position)
                attack_cooldown.start()
                break


func _state_search():
    # Если во время поиска игрок снова выскочил перед глазами — ловим его
    if _can_see_player(player_in_cone_zone):
        player = player_in_cone_zone
        change_state(State.CHASE)
        return
        
    if not has_last_known_position:
        change_state(State.PATROL)
        return
        
    search_timer += get_physics_process_delta_time()
    if global_position.distance_to(last_known_position) > 10:
        _move_toward(last_known_position, patrol_speed)
    else:
        velocity = Vector2.ZERO
        anim.play("idle")
    
    if search_timer >= search_duration:
        search_timer = 0.0
        has_last_known_position = false
        change_state(State.PATROL)


func _move_toward(target: Vector2, move_speed: float):
    nav_agent.target_position = target
    if not nav_agent.is_navigation_finished():
        var next_point = nav_agent.get_next_path_position()
        var direction = (next_point - global_position).normalized()
        velocity = direction * move_speed
        anim.flip_h = velocity.x > 0
        anim.play("move")
    else:
        velocity = Vector2.ZERO
        anim.play("idle")


func _on_vision_cone_entered(body):
    if body.is_in_group("player"):
        player_in_cone_zone = body # Просто запоминаем, что игрок в зоне геометрии конуса


func _on_vision_cone_exited(body):
    if body.is_in_group("player"):
        player_in_cone_zone = null
        if current_state != State.CHASE:
            player = null


func _on_attack_zone_entered(body):
    if body.is_in_group("player") and attack_cooldown.is_stopped():
        GameManager.take_damage(damage)
        body.apply_knockback(global_position)
        attack_cooldown.start()


func _state_knockback():
    velocity = knockback_direction * 150.0
    anim.play("hurt")


func _on_knockback_finished():
    change_state(State.CHASE if player != null else State.PATROL)


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
        velocity = knockback_direction * 200.0
        await anim.animation_finished
        die()
    else:
        anim.play("hurt")


func die():
    is_dying = true
    velocity = Vector2.ZERO
    GameManager.add_scrap(scrap_reward)
    $CollisionShape2D.set_deferred("disabled", true)
    vision_cone.monitoring = false
    attack_zone.monitoring = false
    anim.play("death")
    await anim.animation_finished
    queue_free()
