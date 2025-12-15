extends RigidBody3D
class_name  Car
@export_category("wheels")
@export var wheels: Array[wheel]
@export var acceleration:=800.0
@export var accelCurv:Curve
@export var maxspeed := 50.0


func _physics_process(delta: float) -> void:
	for w in wheels:
		w.apply(delta)
	DebugDraw3D.draw_arrow_ray(global_position+Vector3.UP,linear_velocity,1,Color.YELLOW,0.05)
