extends Skeleton2D

@export var target_skeleton: Skeleton3D

@export var linear_spring_stiffness: float = 120.0
@export var linear_spring_damping: float = 40.0
@export var max_linear_force: float = 9999.0

@export var angular_spring_stiffness: float = 4000.0
@export var angular_spring_damping: float = 80.0
@export var max_angular_force: float = 9999.0

var velocity:Vector2 = Vector2.ZERO
var physicsLimbs
var walkingLimbs
var gunHoldingLimbs
var livingLimbs

enum states {
	wonder,
	attacking,
	runningAway,
	investigating,
	mindControlled
}

var currentState = states.wonder
var walkingDirection = 0
var lastSeenSpot:Vector2 = Vector2.ZERO

var maxHP = 10
var HP = 10
var weapon:Node2D = null
enum weaponStates{
	rest,
	aming
}
var weaponState
@onready var line_of_sight: RayCast2D = $"../PB_torso/LineOfSight"

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
	for limb:RigidBody2D in physicsLimbs:
		limb.contact_monitor = true
		limb.max_contacts_reported = 100

func _physics_process(delta):
	processLimbs(delta)
	
	var newPos:Vector2 = $"../PB_torso".global_position
	
	var targetMonster:CharacterBody2D = findClosestMonster()
	
	if(targetMonster != null && currentState != states.mindControlled):
		lastSeenSpot = targetMonster.global_position
		if(currentState == states.runningAway):
			var distanceToMonster = global_position.distance_to(targetMonster.global_position)
			if(distanceToMonster > 500):
				currentState = states.attacking
		else:
			currentState = states.attacking
	
	match currentState:
		states.wonder:
			walk(walkingDirection)
			var randomNumber = randi_range(0, 100)
			if(randomNumber == 0):
				walkingDirection = randi_range(-1, 1)
		states.attacking:
			if(targetMonster != null):
				var direction = sign(targetMonster.global_position.x-global_position.x)
				var distanceToMonsterx = abs(global_position.x-targetMonster.global_position.x)
				var distanceToMonster = global_position.distance_to(targetMonster.global_position)
				if(distanceToMonsterx < 800):
					direction = 0
				if(distanceToMonster < 100):
					currentState = states.runningAway
				walk(direction)
				gunLogic(targetMonster.global_position)
			else:
				currentState = states.investigating
		states.runningAway:
			if(targetMonster != null):
				var direction = sign(global_position.x-targetMonster.global_position.x)
				walk(direction)
		states.investigating:
			var direction = sign(lastSeenSpot.x-global_position.x)
			walk(direction)
		states.mindControlled:
			pass
	
	#if(targetMonster != null):
		#walk(Input.get_axis("ui_left", "ui_right"))
		#gunLogic(targetMonster.global_position)
	
	newPos += velocity
	global_position = lerp(global_position, newPos, 0.1)


func findClosestMonster():
	var closestMonster = null
	var bestDist = INF
	for player:CharacterBody2D in Globals.players:
		line_of_sight.target_position.x = livingLimbs[0].global_position.distance_to(player.global_position)
		line_of_sight.look_at(player.global_position)
		line_of_sight.force_raycast_update()
		
		var dist = global_position.distance_to(player.global_position)
		if dist < bestDist && !line_of_sight.is_colliding():
			bestDist = dist
			closestMonster = player
	return closestMonster

func gunLogic(target):
	if(weapon == null):
		return
	
	weapon.shoot()
	$TargetRight.global_position = target
	$TargetLeft.global_position = weapon.otherHand.global_position

func walk(direction):
	if(direction > 0):
		$"../AnimationPlayer".play("walkRight")
	elif(direction < 0):
		$"../AnimationPlayer".play("walkLeft")
	else:
		$"../AnimationPlayer".play("RESET")
	for limb:RigidBody2D in walkingLimbs:
		if limb.get_colliding_bodies().size() > 0:
			velocity.y = -limb.linear_velocity.y*2
			velocity.x = direction*50
		else:
			velocity.y += 2


func processLimbs(delta):
	var i = 0
	for limb:RigidBody2D in physicsLimbs:
		var boneTo:Bone2D = bonesToPath[i]
		
		var target_transform: Vector2 = boneTo.global_position
		var current_transform: Vector2 = limb.global_position
		var rotation_difference = angle_difference(limb.global_rotation, boneTo.global_rotation)
		var position_difference:Vector2 = boneTo.global_position - limb.global_position

		var force: Vector2 = hookes_law(position_difference, limb.linear_velocity, linear_spring_stiffness, linear_spring_damping) * HP/maxHP * limb.strengthMultiplyer
		force = force.limit_length(max_linear_force)
		limb.linear_velocity += (force * delta)
		
		var torque = hookes_law(Vector2(rotation_difference, 0), Vector2(limb.angular_velocity, 0), angular_spring_stiffness, angular_spring_damping) * HP/maxHP * limb.strengthMultiplyer
		torque = torque.limit_length(max_angular_force)
		limb.angular_velocity += torque.x * delta
		
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
