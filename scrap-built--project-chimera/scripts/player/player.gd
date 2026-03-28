extends CharacterBody2D

@export var speed: float = 100.0
var last_direction = "down"
var is_attacking = false
var is_knockback = false
var is_invincible = false
var is_dashing = false
var knockback_velocity = Vector2.ZERO

var dash_speed = 400.0
var dash_duration = 0.2
var energy_cost = 25
var energy_regen_rate = 10.0

@onready var anim = $AnimatedSprite2D
@onready var hit_zone = $HitZone
@onready var interaction_zone = $InteractionZone

func _ready():
    hit_zone.body_entered.connect(_on_hit_zone_entered)
    $DashHitZone.body_entered.connect(_on_dash_hit_zone_entered)

func _physics_process(delta: float) -> void:
    if GameManager.player_energy < GameManager.player_max_energy:
        GameManager.restore_energy(energy_regen_rate * delta)
    
    if is_knockback:
        velocity = knockback_velocity
        knockback_velocity = knockback_velocity.lerp(Vector2.ZERO, 0.2)
        if knockback_velocity.length() < 5:
            is_knockback = false
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
        if abs(dir.x) >= abs(dir.y):
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
    GameManager.player_invincible = true
    is_knockback = true
    knockback_velocity = (global_position - from_position).normalized() * 200.0
    await get_tree().create_timer(1.0).timeout
    GameManager.player_invincible = false

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
    if GameManager.player_energy < energy_cost:
        return
    
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
    print("hit zone touched: ", body.name)
    if body.is_in_group("enemy"):
        print("enemy hit!")
        body.apply_knockback(global_position)
        body.take_damage(_get_attack_damage())

func _get_attack_damage() -> int:
    var bonus = 0
    if GameManager.equipped_parts["arms"] != null:
        bonus = GameManager.equipped_parts["arms"].attack_bonus
    return 10 + bonus

func _unhandled_input(event: InputEvent) -> void:
    if event.is_action_pressed("attack") and not is_attacking:
        _perform_attack()
    
    if event.is_action_pressed("special") and not is_attacking:
        _perform_dash()
    
    if event.is_action_pressed("interact"):
        var areas = interaction_zone.get_overlapping_areas()
        if areas.size() > 0:
            var item = areas[0]
            if item.has_method("collect"):
                item.collect()

func _update_hit_zone():
    match last_direction:
        "right":
            hit_zone.position = Vector2(12, 0)
        "left":
            hit_zone.position = Vector2(-12, 0)
        "down":
            hit_zone.position = Vector2(0, 12)
        "up":
            hit_zone.position = Vector2(0, -12)

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