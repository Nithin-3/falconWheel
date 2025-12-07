extends RayCast3D
class_name  wheel

@export_category("wheels")
@export var wheels: Array[RayCast3D]
@export var suspensionStrength:= 47800.0
@export var suspensionDamping:= 1000.0
@export var suspensionPivot := 0.5
@export var wheelRadius:=0.3
@export var positionAdjust:=0.0
@export var is_acc=false

@onready var tier:Node3D = get_child(0)
