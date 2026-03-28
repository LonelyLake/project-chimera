extends Node


var player_hp: float = 50
var player_max_hp: float = 50
var player_energy: float = 50.0
var player_max_energy: float = 100.0
var player_speed_bonus: float = 0.0
var scrap_count: int = 0
var player_invincible = false
var has_key: bool = false

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
    

func repair_player(amount: float):
    player_hp = min(player_hp + amount, player_max_hp)
    hp_changed.emit(player_hp)


func restore_energy(amount: float):
    player_energy = min(player_energy + amount, player_max_energy)
    energy_changed.emit(player_energy)


func add_scrap(amount: int):
    scrap_count += amount
    scrap_changed.emit(scrap_count)
    

func collect_key():
    has_key = true
    key_collected.emit()
    print("Key collected!")


func consume_key():
    has_key = false
    print("Key consumed!")


func add_to_inventory(item: ItemData):
    if item == null: return
    inventory.append(item)
    inventory_changed.emit()
    print("Item added to inventory: ", item.item_name)


func remove_from_inventory(item_name: String):
    for i in range(inventory.size()):
        if inventory[i].item_name == item_name:
            inventory.remove_at(i)
            inventory_changed.emit()
            return true
    return false


func equip_part(part: RobotPart):
    var slot = RobotPart.PartType.keys()[part.type].to_lower()
    
    # Return old part to inventory
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
        print("The robot is disabled!")
