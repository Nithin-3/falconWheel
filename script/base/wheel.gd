extends RayCast3D
class_name  wheel

@export_category("wheels")
@export var wheels: Array[RayCast3D]
@export var suspensionStrength:= 450.0
@export var suspensionDamping:= 100.0
@export var suspensionPivot := 0.5
@export var wheelRadius:=0.5
@export var positionAdjust:=0.0
@export var is_acc=false
@export var deg := 0
@export var turnSpeed := 2.0
@export var grip:Curve

@onready var tier:Node3D = get_child(0)
@onready var car:Car = get_parent()
var breakZ := false

func _unhandled_input(event: InputEvent) -> void:
	breakZ = true if event.is_action_pressed("break") else false


func _physics_process(delta: float) -> void:
	force_raycast_update()
	#suspension(forceDir)
	#accelerate(forceDir,delta)
	#steering(forceDir,delta)
	apply(delta)

func dist(point1:Vector3,point2:Vector3)->float:
	var d = pow(point1.x-point2.x,2)+pow(point1.y-point2.y,2)+pow(point1.z-point2.z,2)
	return pow(d,0.5)

func getLocVelo(point:Vector3)->Vector3:
	return car.linear_velocity + car.angular_velocity.cross(point - car.global_position)

func apply(delta:float):
	var forceDir := tier.global_position - car.global_position # A − B = direction and distance from B to A
	var turn := Input.get_axis("right","left") * turnSpeed
	var move := Input.get_axis("back","front")
	var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
	
	var carBasis := car.global_basis
	if turn and deg:
		rotation.y = clamp(rotation.y + turn * delta,deg_to_rad(-deg),deg_to_rad(deg))
	else :
		rotation.y = move_toward(rotation.y,0,turnSpeed*delta)
		var vl := car.linear_velocity
		var sideways_speed = (vl - carBasis.z * carBasis.z.dot(vl))
		car.apply_central_force(-sideways_speed * 10.0)
	if not is_colliding(): return
	#suspension
	target_position.y = -(suspensionPivot + wheelRadius + positionAdjust)
	var normal := get_collision_normal()
	var contact = get_collision_point()
	var springLen := dist(global_position,contact) - wheelRadius
	tier.position.y =  -springLen
	var vr := normal.dot(getLocVelo(contact)) # Fdamper​=−c Vrel
	var fY := normal * ((suspensionStrength * (suspensionPivot - springLen)) - (suspensionDamping * vr)) # F = k * x - c * v
	
	#stearing
	var v := getLocVelo(tier.global_position)
	var spedX := global_basis.x.dot(v) # * delta
	var spedZ := global_basis.z.dot(v) # * delta
	var friction := grip.sample_baked(absf(spedX/v.length()))
	var drag := 0.04
	var fX :Vector3 = -global_basis.x * spedX * friction * car.mass*gravity*0.25
	var fZ :Vector3 = -global_basis.z * spedZ * drag * car.mass*gravity*0.25
	
	#acceleration
	if is_acc and move:
		#tier.rotate_x(-spedZ / wheelRadius * delta) # rotate tier
		var ac := car.accelCurv.sample_baked(spedZ/car.maxspeed)
		var a := -global_basis.z * car.acceleration * move * ac
		car.apply_force(a,forceDir)
		DebugDraw3D.draw_arrow_ray(tier.global_position,a/car.mass,1,Color.RED,0.1)
	
	car.apply_force(fY+fX+fZ,forceDir)
	DebugDraw3D.draw_arrow_ray(tier.global_position,fY/car.mass,1,Color.GREEN,0.1)
	DebugDraw3D.draw_arrow_ray(tier.global_position,fX/car.mass,1,Color.BLUE,0.1)
	DebugDraw3D.draw_arrow_ray(tier.global_position,fZ/car.mass,1,Color.REBECCA_PURPLE,0.1)
