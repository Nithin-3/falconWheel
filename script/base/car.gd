extends RigidBody3D
class_name  Car
@export_category("wheels")
@export var wheels: Array[wheel]
@export var acceleration:=50.0
@export var deceleration:=60.0
@export var accelCurv:Curve
@export var maxspeed := 5.0

func _physics_process(_delta: float) -> void:
	var ground = true
	for wel in wheels:
		if not wel.is_colliding():
			ground=false
	if ground:
		center_of_mass = Vector3.ZERO
	else :
		center_of_mass_mode = RigidBody3D.CENTER_OF_MASS_MODE_CUSTOM
		center_of_mass = Vector3.DOWN * 0.5
	DebugDraw3D.draw_arrow_ray(global_position+Vector3.UP,linear_velocity,1,Color.YELLOW,0.05)
