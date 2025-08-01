extends Skeleton2D

@export var linear_spring_stiffness: float = 120.0
@export var linear_spring_damping: float = 40.0
@export var max_linear_force: float = 9999.0

@export var angular_spring_stiffness: float = 4000.0
@export var angular_spring_damping: float = 80.0
@export var max_angular_force: float = 9999.0

var velocity:Vector2 = Vector2.ZERO
var physicsLimbs:Array
var walkingLimbs
var gunHoldingLimbs
var livingLimbs
var numberOfLivingLimbs
@export var bodyStrength = 1

enum states {
	wonder,
	attacking,
	runningAway,
	scared,
	investigating,
	gettingHurt,
	hide,
	gettingUp,
	mindControlled
}

var currentState = states.wonder
var walkingDirection = randi_range(-1, 1)
var lastSeenSpot:Vector2 = Vector2.ZERO

var maxHP = 10
@export var HP = 10
var weapon:Node2D = null
enum weaponStates{
	rest,
	aming
}
var weaponState
@onready var line_of_sight: RayCast2D = $"../PB_torso/LineOfSight"
@onready var sight: Polygon2D = $"../PB_Head/flashLight/sight"
@onready var flash_light: Node2D = $"../PB_Head/flashLight"
@onready var floor_check: RayCast2D = $"../PB_torso/floorCheck"
@onready var wall_cast: RayCast2D = $"../PB_torso/wallCast"
@onready var floor_dist: RayCast2D = $"../PB_torso/floorDist"

@onready var bonesToPath = [
	$torso, 
	$torso/kneck/head,
	$torso/hipLeft, 
	$torso/hipLeft/upperLegLeft, 
	$torso/hipRight, 
	$torso/hipRight/upperLegRight,
	$torso/kneck/sholderLeft,
	$torso/kneck/sholderLeft/upperArmLeft,
	$torso/kneck/sholderRight,
	$torso/kneck/sholderRight/upperArmRight
]

# Called when the node enters the scene tree for the first time.
func _ready():
	physicsLimbs = get_parent().get_children().filter(func(x): return x is RigidBody2D)
	walkingLimbs = filterLimbs(Globals.abilities.walk)
	gunHoldingLimbs = filterLimbs(Globals.abilities.hold)
	livingLimbs = filterLimbs(Globals.abilities.live)
	numberOfLivingLimbs = livingLimbs.size()
	for limb:RigidBody2D in physicsLimbs:
		limb.contact_monitor = true
		limb.max_contacts_reported = 100

func _physics_process(delta):
	if(HP == 0):
		return
	processLimbs(delta)
	if(!is_multiplayer_authority()):
		return
	if($"../PB_torso" == null):
		return
	var newPos:Vector2 = $"../PB_torso".global_position
	
	if(randi_range(0, 3) == 0):
		enemyAI()
	
	floor_dist.target_position.x = walkingDirection*50
	if(floor_dist.is_colliding()):
		velocity.y = -(1/(floor_dist.get_collision_point().y-global_position.y)*800)
	velocity.y += 6
	
	newPos += velocity
	global_position = lerp(global_position, newPos, 0.1)

func enemyAI():
	var targetMonster:CharacterBody2D = findClosestMonster()
	
	if(walkingDirection != 0):
		wall_cast.scale.x = walkingDirection
		floor_check.scale.x = walkingDirection
	
	if(targetMonster != null):
		lastSeenSpot = targetMonster.global_position
	
	match currentState:
		states.wonder:
			move(walkingDirection, true)
			if(wall_cast.is_colliding() || !floor_check.is_colliding()):
				walkingDirection = -walkingDirection
			var randomNumber = randi_range(0, 50)
			if(randomNumber == 0):
				walkingDirection = randi_range(-1, 1)
			if(targetMonster != null):
				currentState = states.attacking
			
			if(walkingDirection != 0):
				if(walkingDirection < 0):
					flash_light.rotation = PI
				else:
					flash_light.rotation = 0
		states.attacking:
			if(targetMonster != null):
				var direction = sign(targetMonster.global_position.x-global_position.x)
				var distanceToMonsterx = abs(global_position.x-targetMonster.global_position.x)
				var distanceToMonster = global_position.distance_to(targetMonster.global_position)
				var directionToMonster = global_position.angle_to_point(targetMonster.global_position)
				
				flash_light.rotation = directionToMonster
				
				if(distanceToMonsterx > 800):
					direction = walkingDirection
				if(distanceToMonsterx < 800):
					direction *= -1
				if(distanceToMonster < 300):
					if(wall_cast.is_colliding() || !floor_check.is_colliding()):
						direction = 0
					else:
						currentState = states.runningAway
				
				walkingDirection = direction
				
				move(walkingDirection, false)
				gunLogic(lastSeenSpot)
			else:
				currentState = states.investigating
		states.runningAway:
			var direction = sign(global_position.x-lastSeenSpot.x)
			walkingDirection = direction
			move(walkingDirection, false)
			var distanceToMonster = global_position.distance_to(lastSeenSpot)
			if(distanceToMonster > 500):
				currentState = states.investigating
			
			if(wall_cast.is_colliding() || !floor_check.is_colliding()):
				currentState = states.attacking
				move(0, false)
			
			if(walkingDirection != 0):
				if(walkingDirection < 0):
					flash_light.rotation = PI
				else:
					flash_light.rotation = 0
		states.scared:
			var direction = sign(global_position.x-lastSeenSpot.x)
			walkingDirection = direction
			move(walkingDirection, false)
			if(wall_cast.is_colliding() || !floor_check.is_colliding()):
				currentState = states.attacking
			if(walkingDirection != 0):
				if(walkingDirection < 0):
					flash_light.rotation = PI
				else:
					flash_light.rotation = 0
		states.hide:
			$"../AnimationPlayer".play("hide")
			move(0, false)
		states.investigating:
			var direction = sign(lastSeenSpot.x-global_position.x)
			if(abs(lastSeenSpot.x-global_position.x) > 100):
				walkingDirection = direction
			else:
				walkingDirection = 0
				currentState = states.wonder
			move(walkingDirection, true)
			
			var directionToLastSeenSpot = global_position.angle_to_point(lastSeenSpot)
			flash_light.rotation = directionToLastSeenSpot
			
			if(targetMonster != null):
				currentState = states.attacking
		states.gettingHurt:
			bodyStrength += 0.005
			velocity = Vector2.ZERO
			if(bodyStrength >= 0.5):
				bodyStrength = 1
				currentState = states.scared
		states.mindControlled:
			pass

@rpc("any_peer", "reliable", "call_local")
func removeLimb(limb:RigidBody2D):
	physicsLimbs.erase(limb)
	walkingLimbs.erase(limb)
	gunHoldingLimbs.erase(limb)
	livingLimbs.erase(limb)

func takeDamage(damage):
	currentState = states.gettingHurt
	bodyStrength = 0
	if(HP > 0):
		HP -= damage
	HP = clamp(HP, 0, INF)
	$"../AnimationPlayer".stop()

func findClosestMonster():
	if(livingLimbs.size() < numberOfLivingLimbs):
		HP = 0
		return
	var closestMonster = null
	var bestDist = INF
	for player:CharacterBody2D in Globals.players:
		line_of_sight.target_position.x = livingLimbs[0].global_position.distance_to(player.global_position)-100
		line_of_sight.look_at(player.global_position)
		line_of_sight.force_raycast_update()
		
		var isPlayerInSight = Geometry2D.is_point_in_polygon(to_local(player.global_position).rotated(-flash_light.global_rotation), sight.polygon)
		
		var dist = global_position.distance_to(player.global_position)
		if dist < bestDist && !line_of_sight.is_colliding() && isPlayerInSight:
			bestDist = dist
			closestMonster = player
	return closestMonster

func gunLogic(target):
	if(weapon == null):
		return
	
	weapon.shoot.rpc()
	$TargetRight.global_position = target
	$TargetLeft.global_position = weapon.otherHand.global_position

func move(direction, walking):
	$TargetRight.global_position = $torso/kneck/head.global_position + Vector2(50*direction, 0)
	if(weapon != null):
		$TargetLeft.global_position = weapon.otherHand.global_position
	if(direction > 0):
		if(walking):
			$"../AnimationPlayer".play("walkRight")
		else:
			$"../AnimationPlayer".play("runRight")
			
	elif(direction < 0):
		if(walking):
			$"../AnimationPlayer".play("walkLeft")
		else:
			$"../AnimationPlayer".play("runLeft")
	else:
		$"../AnimationPlayer".play("RESET")
	for limb:RigidBody2D in walkingLimbs:
		if limb.get_colliding_bodies().size() > 0:
			if(walking):
				velocity.x = direction*50
			else:
				velocity.x = direction*200

func processLimbs(delta):
	var i = 0
	for limb:RigidBody2D in physicsLimbs:
		var boneTo:Bone2D = bonesToPath[i]
		
		var target_transform: Vector2 = boneTo.global_position
		var current_transform: Vector2 = limb.global_position
		var rotation_difference = angle_difference(limb.global_rotation, boneTo.global_rotation)
		var position_difference:Vector2 = boneTo.global_position - limb.global_position
		
		var force: Vector2 = hookes_law(position_difference, limb.linear_velocity, linear_spring_stiffness, linear_spring_damping) * HP/maxHP * limb.strengthMultiplyer * bodyStrength
		force = force.limit_length(max_linear_force)
		limb.linear_velocity += (force * delta)
		
		var torque = hookes_law(Vector2(rotation_difference, 0), Vector2(limb.angular_velocity, 0), angular_spring_stiffness, angular_spring_damping) * HP/maxHP * limb.strengthMultiplyer * bodyStrength
		torque = torque.limit_length(max_angular_force)
		limb.angular_velocity += torque.x * delta
		
		if(position_difference.distance_to(Vector2.ZERO) > 500):
			limb.removeSelfFromBody.rpc()
		
		i += 1

func filterLimbs(ability):
	return physicsLimbs.filter(
		func(x):
			for limbAbility in x.limbAbilitys:
				if(limbAbility == ability):
					return true
			false
	)

func hookes_law(displacement: Vector2, current_velocity: Vector2, stiffness: float, damping: float) -> Vector2:
	return (stiffness * displacement) - (damping * current_velocity)
