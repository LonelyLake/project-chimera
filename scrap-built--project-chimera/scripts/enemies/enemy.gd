class_name Enemy
extends CharacterBody2D

enum State { IDLE, CHASE, SEARCH, ATTACK, KNOCKBACK, PATROL }

@export var hp: int = 30
@export var speed: float = 60.0
@export var damage: int = 10
@export var scrap_reward: int = 5
@export var attack_range: float = 20.0
@export var update_path_interval: float = 0.3

var current_state = State.IDLE
var player = null
var last_known_position = Vector2.ZERO
var has_last_known_position = false
var path_timer = 0.0
var knockback_direction = Vector2.ZERO
var is_dying = false


func _physics_process(delta):
    if is_dying:
        velocity = velocity.lerp(Vector2.ZERO, 0.1)
        move_and_slide()
        return
    
    path_timer += delta
    
    match current_state:
        State.IDLE:
            _state_idle()
        State.CHASE:
            _state_chase()
        State.SEARCH:
            _state_search()
        State.ATTACK:
            _state_attack()
        State.KNOCKBACK:
            _state_knockback()
        State.PATROL:
            _state_patrol()
    
    move_and_slide()


func _state_idle():
    velocity = Vector2.ZERO

func _state_chase():
    if player == null:
        change_state(State.SEARCH)
        return
    
    last_known_position = player.global_position
    has_last_known_position = true
    
    if player.global_position.distance_to(global_position) <= attack_range:
        change_state(State.ATTACK)
        return
    
    if path_timer >= update_path_interval:
        path_timer = 0.0
        _update_path(player.global_position)

func _state_search():
    if not has_last_known_position:
        change_state(State.IDLE)
        return
    
    if path_timer >= update_path_interval:
        path_timer = 0.0
        _update_path(last_known_position)
    
    if global_position.distance_to(last_known_position) < 10:
        has_last_known_position = false
        change_state(State.IDLE)

func _state_attack():
    velocity = Vector2.ZERO


func _state_patrol():
    pass


func _update_path(target: Vector2):
    pass


func change_state(new_state: State):
    current_state = new_state


func take_damage(amount: int):
    if is_dying:
        return
    hp -= amount
    if hp <= 0:
        die()


func apply_knockback(from_position: Vector2, force: float = 150.0):
    knockback_direction = (global_position - from_position).normalized()
    change_state(State.KNOCKBACK)


func _state_knockback():
    velocity = knockback_direction * 150.0


func die():
    GameManager.add_scrap(scrap_reward)
    queue_free()


func on_player_entered(body):
    if body.is_in_group("player"):
        player = body
        change_state(_get_initial_state())
        

func _get_initial_state() -> State:
    return State.CHASE


func on_player_exited(body):
    if body.is_in_group("player"):
        player = null
        if current_state == State.CHASE:
            change_state(State.SEARCH)         
