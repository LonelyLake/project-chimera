extends Node

var player_hp: float = 100.0
var player_max_hp: float = 100.0
var player_energy: float = 100.0
var player_max_energy: float = 100.0
var player_speed_bonus: float = 0.0
var scrap_count: int = 200
var player_invincible = false
var keys_collected: int = 0

var inventory: Array[ItemData] = []
var equipped_parts = {
    "head": null,
    "torso": null,
    "arms": null,
    "wheel": null
}
var collected_parts = []

signal hp_changed(new_val)
signal max_hp_changed(new_val)
signal energy_changed(new_val)
signal scrap_changed(new_val)
signal key_collected()
signal inventory_changed()
signal player_died

const DEFAULT_HEAD = preload("res://resources/parts/light_head.tres")
const DEFAULT_TORSO = preload("res://resources/parts/light_torso.tres")
const DEFAULT_ARMS = preload("res://resources/parts/light_arms.tres")
const DEFAULT_WHEEL = preload("res://resources/parts/light_wheel.tres")


func _ready() -> void:
    equipped_parts["head"] = DEFAULT_HEAD
    equipped_parts["torso"] = DEFAULT_TORSO
    equipped_parts["arms"] = DEFAULT_ARMS
    equipped_parts["wheel"] = DEFAULT_WHEEL
    
    recalculate_stats()
    
    player_hp = player_max_hp
    player_energy = player_max_energy
    hp_changed.emit(player_hp)
    energy_changed.emit(player_energy)


func repair_player(amount: float):
    player_hp = min(player_hp + amount, player_max_hp)
    hp_changed.emit(player_hp)


func restore_energy(amount: float):
    player_energy = min(player_energy + amount, player_max_energy)
    energy_changed.emit(player_energy)


func add_scrap(amount: int):
    scrap_count += amount
    scrap_changed.emit(scrap_count)


func collect_level_key():
    keys_collected += 1
    key_collected.emit()
    print("Level key collected! Total: ", keys_collected)

func collect_key():
    keys_collected += 1
    key_collected.emit()
    print("Key collected!")


func consume_key():
    keys_collected = maxi(0, keys_collected - 1)
    print("Key consumed!")


func add_to_inventory(item: ItemData):
    if item == null: return
    inventory.append(item)
    inventory_changed.emit()
    print("Item added to inventory: ", item.item_name)


func use_consumable_by_type(type: String) -> bool:
    for item in inventory:
        if item is Consumable:
            
            if type == "hp" and item.hp_restore > 0:
                repair_player(item.hp_restore)
                inventory.erase(item)
                inventory_changed.emit()
                print("Использована аптечка: ", item.item_name)
                return true
                
            elif type == "energy" and item.energy_restore > 0:
                restore_energy(item.energy_restore)
                inventory.erase(item)
                inventory_changed.emit()
                print("Использована батарейка: ", item.item_name)
                return true
                
    print("Нет подходящих предметов в инвентаре!")
    return false

func remove_from_inventory(item_name: String):
    for i in range(inventory.size()):
        if inventory[i].item_name == item_name:
            inventory.remove_at(i)
            inventory_changed.emit()
            return true
    return false


func equip_part(part: RobotPart):
    var slot = RobotPart.PartType.keys()[part.type].to_lower()
    
    var old_part = equipped_parts[slot]
    if old_part != null:
        inventory.append(old_part)
    
    equipped_parts[slot] = part
    recalculate_stats()


func recalculate_stats():
    var hp_bonus = 0
    var speed_bonus = 0.0
    
    for slot in equipped_parts.values():
        if slot != null:
            hp_bonus += slot.hp_bonus
            speed_bonus += slot.speed_bonus
    
    player_max_hp = 100 + hp_bonus
    player_hp = min(player_hp, player_max_hp)
    player_speed_bonus = speed_bonus
    hp_changed.emit(player_hp)
    max_hp_changed.emit(player_max_hp)


func take_damage(amount: int):
    if player_invincible:
        return
    player_hp -= amount
    player_hp = clamp(player_hp, 0, player_max_hp)
    hp_changed.emit(player_hp)
    if player_hp <= 0:
        player_died.emit()


func set_world_pause(pause: bool):
    var player = get_tree().get_first_node_in_group("player")
    if player and is_instance_valid(player):
        player.set_physics_process(!pause)
    
    var enemies = get_tree().get_nodes_in_group("enemy")
    for enemy in enemies:
        if is_instance_valid(enemy):
            enemy.set_physics_process(!pause)
