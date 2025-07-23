extends Line2D

var slingTo:Vector2
var startGlobalPosition
var globalPositions = []
@onready var web_check: RayCast2D = $webCheck
@onready var un_wind_check: RayCast2D = $unWindCheck
var webCheckMinDistance = 20

func _ready() -> void:
	startGlobalPosition = global_position
	for point:Vector2 in points:
		globalPositions.append(to_global(point))

func _process(delta: float) -> void:
	if(!is_multiplayer_authority()):
		return
	global_rotation = 0
	
	web_check.target_position = points[1]-(points[1].normalized()*10)
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

func insertPointToPointsAndGlobalPositions(index, pointLocal, pointGlobal):
	add_point(pointLocal, index)
	globalPositions.insert(index, pointGlobal)
