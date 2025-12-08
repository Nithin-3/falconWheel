extends RayCast3D
class_name  wheel

@export_category("wheels")
@export var wheels: Array[RayCast3D]
@export var suspensionStrength:= 100.0
@export var suspensionDamping:= 10.0
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
var move := 0.0

func _unhandled_input(event: InputEvent) -> void:
	breakZ = true if event.is_action_pressed("break") else false
	if event.is_action_pressed("front"):
		move = 1
	elif event.is_action_pressed("back"):
		move = -1
	if event.is_action_released("back") or event.is_action_released("front"):
		move=0

func _physics_process(delta: float) -> void:
	force_raycast_update()
	var forceDir := tier.global_position - car.global_position # A − B = direction and distance from B to A
	suspension(forceDir)
	accelerate(forceDir,delta)
	steering(forceDir,delta)

func dist(point1:Vector3,point2:Vector3)->float:
	var d = pow(point1.x-point2.x,2)+pow(point1.y-point2.y,2)+pow(point1.z-point2.z,2)
	return pow(d,0.5)

func getLocVelo(point:Vector3)->Vector3:
	return car.linear_velocity + car.angular_velocity.cross(point - car.global_position)


func suspension(forceDir:Vector3)->void:
	if not is_colliding(): return
	target_position.y = -(suspensionPivot + wheelRadius + positionAdjust)
	var contact = get_collision_point()
	var normal = get_collision_normal()
	var springLen := dist(global_position,contact) - wheelRadius
	var displacement := suspensionPivot - springLen
	tier.position.y =  -springLen
	var v = normal.dot(getLocVelo(contact)) # Fdamper​=−c Vrel
	var f = normal * ((suspensionStrength * displacement) - (suspensionDamping * v)) # F = k * x - c * v
	car.apply_force(f,forceDir)
	DebugDraw3D.draw_arrow_ray(tier.global_position,clamp(f,normal*0.5,normal*2),1,Color.GREEN,0.1)

func steering(focDir:Vector3,delta:float)->void:
	var turn = Input.get_axis("right","left")
	if turn and deg:
		rotation.y = clamp(rotation.y + turn * delta,deg_to_rad(-deg),deg_to_rad(deg))
	else :
		rotation.y = move_toward(rotation.y,0,turnSpeed*delta)
		var v = car.linear_velocity
		var forward = car.global_basis.z
		var sideways_speed = (v - forward * forward.dot(v))
		car.apply_central_force(-sideways_speed * 10.0)
	if not is_colliding(): return
	var bas := global_basis
	var velo := getLocVelo(tier.global_position)
	var steerX = bas.x.dot(velo) * delta # f=ma   a=dv/dt
	var gripFac = absf(steerX / velo.length())
	var traction := grip.sample_baked(gripFac)
	if breakZ:
		traction = 1.0 
	var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
	var fX = -car.global_basis.x * steerX * traction * (car.mass*gravity/4.0) # f= ma
	#drag
	var veloZ := bas.z.dot(car.linear_velocity)
	var drag := 0.01
	var fD = -car.global_basis.z * veloZ *  drag * (car.mass*gravity/4.0) # f= f1+f2 == drag + slip
	var fT = fD + fX
	car.apply_force(fT,focDir)
	DebugDraw3D.draw_arrow_ray(tier.global_position,fD,1,Color.BLUE,0.02)
	DebugDraw3D.draw_arrow_ray(tier.global_position,fX,1,Color.AQUA,0.02)
	DebugDraw3D.draw_arrow_ray(tier.global_position,fT,1,Color.LIGHT_BLUE,0.02)


func accelerate(forceDir:Vector3,delta:float) -> void:
	var forward := -car.global_basis.z
	var velo := forward.dot(car.linear_velocity)
	tier.rotate_x(-velo /  wheelRadius * delta)
	if is_colliding() and is_acc and move:
		var speedRat := velo / car.maxspeed
		var ac := car.accelCurv.sample_baked(speedRat)
		var forceVector := forward * car.acceleration * move * ac
		car.apply_force(forceVector,forceDir)
		car.apply_torque(-forceDir.cross(forceVector))
		DebugDraw3D.draw_arrow_ray(tier.global_position,forceVector,1,Color.RED,0.1)
