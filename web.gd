extends Line2D

var slingTo:Vector2
var startGlobalPosition
var globalPositions = []
var objectConectedTo = null
var connectedPointOffset = Vector2.ZERO
@onready var web_check: RayCast2D = $webCheck
@onready var un_wind_check: RayCast2D = $unWindCheck
const WEB_COLLISION = preload("res://web_collision.tscn")
var webCheckMinDistance = 20
var isSetWeb = false
var settingDown = false
var settingDownDelay = 1

func _ready() -> void:
	web_check.collide_with_areas = true
	un_wind_check.collide_with_areas = true
	startGlobalPosition = global_position
	for point:Vector2 in points:
		globalPositions.append(to_global(point))
	
	if(objectConectedTo != null):
		connectedPointOffset = to_global(points[points.size()-1]) - objectConectedTo.global_position

func _process(delta: float) -> void:
	if(settingDown && !isSetWeb):
		settingDownDelay -= delta
		if(settingDownDelay <= 0):
			setWeb()
	
	global_rotation = 0
	
	if(!is_multiplayer_authority() || isSetWeb):
		#setWebUpdates()
		return
	
	updateWeb()

#func setWebUpdates():
	#if(objectConectedTo != null):
		#globalPositions[globalPositions.size()-1] = objectConectedTo.global_position+connectedPointOffset
		#var globalPoint:Vector2 = globalPositions[globalPositions.size()-1]
		#points[points.size()-1] = globalPoint-global_position
		#if(objectConectedTo is RigidBody2D):
			#objectConectedTo.linear_velocity = globalPoint.direction_to(objectConectedTo.global_position)*1000

func updateWeb():
	web_check.target_position = points[1]-(points[1].normalized()*10)
	web_check.force_raycast_update()
	if(points.size() > 2):
		un_wind_check.position = points[0]
		un_wind_check.target_position = points[2]-(points[2].normalized()*10)-un_wind_check.position
		un_wind_check.force_raycast_update()
		if(!un_wind_check.is_colliding()):
			remove_point(1)
			globalPositions.remove_at(1)
	
	if(web_check.is_colliding()):
		var checkPosGlobal = web_check.get_collision_point()
		var checkPosLocal = to_local(checkPosGlobal)
		if (web_check.target_position.distance_to(checkPosLocal) > webCheckMinDistance):
			insertPointToPointsAndGlobalPositions(1, checkPosLocal, checkPosGlobal)
	
	for i in range(1, globalPositions.size()):
		var globalPoint = globalPositions[i]
		points[i] = globalPoint-global_position
	#if(objectConectedTo != null):
		#globalPositions[globalPositions.size()-1] = objectConectedTo.global_position+connectedPointOffset
		#if(objectConectedTo is RigidBody2D):
			#objectConectedTo.linear_velocity = -globalPositions[globalPositions.size()-1].direction_to(objectConectedTo.global_position)*1000
		#points[points.size()-1] += (objectConectedTo.global_position-global_position)

func insertPointToPointsAndGlobalPositions(index, pointLocal, pointGlobal):
	add_point(pointLocal, index)
	globalPositions.insert(index, pointGlobal)

#@rpc("any_peer", "reliable", "call_remote")
func setWeb():
	for i in range(points.size()-1):
		var point1 = points[i]
		var point2 = points[i+1]
		
		var webCollision = WEB_COLLISION.instantiate()
		#webCollision.set_multiplayer_authority(pid)
		webCollision.position = point1
		webCollision.look_at(point2)
		webCollision.scale.x = point1.distance_to(point2)
		add_child(webCollision)
		print("created section " + str(i))
	
	isSetWeb = true
	print("web set")
