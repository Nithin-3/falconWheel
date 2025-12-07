extends RigidBody3D

@export_category("wheels")
@export var wheels: Array[wheel]
@export var acceleration:=600.0
@export var deceleration:=600.0
@export var accelCurv:Curve

@export var maxspeed := 20.0
var move := 0.0
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("front"):
		move = 1
	elif event.is_action_pressed("back"):
		move = -1
	if event.is_action_released("back") or event.is_action_released("front"):
		move=0

func _physics_process(_delta: float) -> void:
	var ground = true
	for wel in wheels:
		if not wel.is_colliding():
			ground=false
		wel.force_raycast_update()
		accelerate(wel)
		suspension(wel)
	if ground:
		center_of_mass = Vector3.ZERO
	else :
		center_of_mass_mode = RigidBody3D.CENTER_OF_MASS_MODE_CUSTOM
		center_of_mass = Vector3.DOWN * 0.6

func dist(point1:Vector3,point2:Vector3)->float:
	var d = pow(point1.x-point2.x,2)+pow(point1.y-point2.y,2)+pow(point1.z-point2.z,2)
	return pow(d,0.5)

func getLocVelo(point:Vector3)->Vector3:
	return linear_velocity+angular_velocity.cross(point-global_position)

func suspension(w:wheel)->void:
	if not w.is_colliding():
		return
	w.target_position.y = -(w.suspensionPivot + w.wheelRadius + w.positionAdjust)
	var contact = w.get_collision_point()
	var normal = w.get_collision_normal()
	var springLen := dist(w.global_position,contact)-w.wheelRadius
	var displacement := w.suspensionPivot - springLen
	w.tier.position.y =  -springLen
	var d = normal.dot(getLocVelo(contact)) # Fdamper​=−c Vrel
	var f = (w.suspensionStrength * displacement) - (w.suspensionDamping * d) # F = k * x - c * v
	var fNormal = f * normal
	var fDir = w.tier.global_position - global_position # A − B = direction and distance from B to A
	var torque = fDir.cross(fNormal)
	apply_force(fNormal,fDir)
	apply_torque(-torque)

func accelerate(whe: wheel) -> void:
	var forward := -whe.global_basis.z
	var velo := forward.dot(linear_velocity)
	whe.tier.rotate_x(-velo * get_process_delta_time() * 2 * PI * whe.wheelRadius)
	if whe.is_colliding() and whe.is_acc:
		var ground = whe.tier.global_position
		var fDir = ground - global_position # A − B = direction and distance from B to A
		if move:
			var speedRat := velo / maxspeed
			var ac := accelCurv.sample_baked(speedRat)
			var forceVector := forward * acceleration * move * ac
			var torque = fDir.cross(forceVector)
			apply_force(forceVector,fDir)
			apply_torque(-torque)
			DebugDraw3D.draw_arrow(ground,forceVector,Color.GREEN,0.2)
		elif abs(velo) > 0.02 :
			var forceVector = global_basis.z*deceleration*signf(velo)
			var torque = fDir.cross(forceVector)
			apply_force(forceVector,fDir)
			apply_torque(-torque)
			DebugDraw3D.draw_arrow(ground,forceVector,Color.RED,0.2)
