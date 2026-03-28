class_name RobotPart
extends ItemData


enum PartType { HEAD, TORSO, ARMS, WHEEL }

@export var type: PartType

@export_group("Characteristics")
@export var hp_bonus: int = 0
@export var speed_bonus: float = 0.0
@export var attack_bonus: int = 0
