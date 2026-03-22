extends Resource
class_name RobotPart


enum PartType { HEAD, TORSO, ARMS, LEGS }

@export var part_name: String = "New part"
@export var type: PartType
@export var texture: Texture2D # FOR SPRITE

@export_group("Characteristics")
@export var hp_bonus: int = 0
@export var speed_bonus: float = 0.0
@export var attack_bonus: int = 0

@export_group("Description")
@export_multiline var description: String = ""
