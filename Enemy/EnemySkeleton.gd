extends Skeleton2D

@export var linear_spring_stiffness: float = 120.0
@export var linear_spring_damping: float = 40.0
@export var max_linear_force: float = 9999.0

@export var angular_spring_stiffness: float = 4000.0
@export var angular_spring_damping: float = 80.0
@export var max_angular_force: float = 9999.0

var velocity:Vector2 = Vector2.ZERO
var physicsLimbs:Array
var walkingLimbs:Array
var gunHoldingLimbs
var livingLimbs
var hearingLimbs
var mainHoldingLimbs
var numberOfLivingLimbs
@export var bodyStrength = 1
var targetSound = null

enum states {
	patrolling,
	suspicious,
	alerted,
	hostile,
	searching,
	callingForBackup,
	stuck,
	getRidOfWebs,
	mindControlled
}
var stateTimer = 0

var currentState = states.patrolling
var walkingDirection = randi_range(-1, 1)
var lastSeenSpot:Vector2 = Vector2.ZERO
var lastSeenWeb: Vector2 = Vector2.ZERO

var maxHP = 10
@export var HP = 10
var weapon:Node2D = null
enum weaponStates{
	rest,
	aming
}
var stuckLimb = null
var weaponState
@onready var line_of_sight: RayCast2D = $"../PB_torso/LineOfSight"
@onready var sight: Polygon2D = $"../PB_Head/flashLight/sight"
@onready var flash_light: Node2D = $"../PB_Head/flashLight"
@onready var floor_check: RayCast2D = $"../PB_torso/floorCheck"
@onready var wall_cast: RayCast2D = $"../PB_torso/wallCast"
@onready var floor_dist: RayCast2D = $"../PB_torso/floorDist"
@onready var awarness_area: Area2D = $"../PB_torso/awarnessArea"

@onready var SOUND = preload("res://sound.tscn")

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
	hearingLimbs = filterLimbs(Globals.abilities.hear)
	mainHoldingLimbs = filterLimbs(Globals.abilities.mainHolding)
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
		enemyAI(delta)
	
	floor_dist.target_position.x = walkingDirection*50
	if(floor_dist.is_colliding()):
		velocity.y = -(1/(floor_dist.get_collision_point().y-global_position.y)*800)
	velocity.y += 6
	
	newPos += velocity
	global_position = lerp(global_position, newPos, 0.1)

func enemyAI(delta):
	if(bodyStrength < 1):
		bodyStrength += delta
	elif(bodyStrength > 1):
		bodyStrength = 1
	
	if(currentState == states.patrolling):
		targetSound = null
	
	var targetMonster:CharacterBody2D = findClosestMonster()
	var ears:Area2D
	if(hearingLimbs.size() > 0):
		ears = hearingLimbs[0].get_child(0)
		if(ears.get_overlapping_areas().size() != 0):
			targetSound = ears.get_overlapping_areas()[0].global_position
	
	if(walkingDirection != 0):
		wall_cast.scale.x = walkingDirection
		floor_check.scale.x = walkingDirection
	
	if(targetMonster != null):
		lastSeenSpot = targetMonster.global_position
	
	match currentState:
		states.patrolling:
			findWebs()
			lastSeenWeb = Vector2.ZERO
			move(walkingDirection, true)
			if(walkingDirection != 0):
				if(walkingDirection < 0):
					flash_light.rotation = PI
				else:
					flash_light.rotation = 0
			if(randi_range(0, 100) == 0):
				if(walkingDirection != 0):
					walkingDirection = 0
				else:
					if(randi_range(0, 1) == 0):
						walkingDirection = -1
					else:
						walkingDirection = 1
			if(targetMonster != null):
				currentState = states.alerted
			elif(targetSound != null):
				currentState = states.suspicious
		states.suspicious:
			findWebs()
			look_around(targetSound)
			if(targetMonster != null):
				currentState = states.alerted
			else:
				stateTimer += delta
				if(stateTimer > 3):
					currentState = states.patrolling
					stateTimer = 0
		states.alerted:
			findWebs()
			aimWeapon(lastSeenSpot)
			if(targetMonster != null):
				currentState = states.hostile
			else:
				stateTimer += delta
				if(stateTimer > 2):
					currentState = states.searching
					stateTimer = 0
		states.hostile:
			findWebs()
			chase_player(lastSeenSpot)
			if(targetMonster != null):
				aimWeapon(targetMonster.global_position)
				shootWeapon()
			else:
				stateTimer += delta
				if(stateTimer > 3):
					currentState = states.callingForBackup
					stateTimer = 0
		states.searching:
			findWebs()
			search_area()
			if(targetMonster != null):
				currentState = states.hostile
			else:
				stateTimer += delta
				if(stateTimer > 1):
					currentState = states.patrolling
					stateTimer = 0
		states.stuck:
			stateTimer += delta
			if(stateTimer > 1):
				call_for_help()
				stateTimer = 0
			if(stuckLimb == null):
				currentState = states.searching
			else:
				if(walkingDirection == 0):
					walkingDirection = sign(global_position.x-stuckLimb.global_position.x)
				move(-walkingDirection, false)
		states.getRidOfWebs:
			var direction = -sign(lastSeenWeb.x-global_position.x)
			var distance = abs(lastSeenWeb.x-global_position.x)
			if(distance < 400):
				walkingDirection = direction
			else:
				walkingDirection = 0
			move(walkingDirection, true)
			
			aimWeapon(lastSeenWeb)
			shootWeapon()
			
			if(lastSeenWeb == Vector2.ZERO):
				if(targetMonster != null):
					currentState = states.hostile
				currentState = states.searching
			
		states.callingForBackup:
			move(0, false)
			call_for_help()
			currentState = states.searching
	
	avoidWebs()

func call_for_help():
	makeSound(global_position, 500)

func search_area():
	var direction = sign(lastSeenSpot.x-global_position.x)
	var distanceToSpotx = abs(global_position.x-lastSeenSpot.x)
	var directionToSpot = global_position.angle_to_point(lastSeenSpot)
	
	move(direction, true)
	flash_light.rotation = sin(Time.get_unix_time_from_system())*PI/2-PI/2

func chase_player(targetPoint):
	var direction = sign(targetPoint.x-global_position.x)
	var distanceToPointx = abs(global_position.x-targetPoint.x)
	#var distanceToPoint = global_position.distance_to(targetPoint)
	#var directionToPoint = global_position.angle_to_point(targetPoint)
	
	if(distanceToPointx > 500):
		move(direction, false)
	else:
		move(0, false)

func look_around(targetSound):
	var direction = sign(targetSound.x-global_position.x)
	var distanceToSoundx = abs(global_position.x-targetSound.x)
	#var distanceToSound = global_position.distance_to(targetSound)
	var directionToSound = global_position.angle_to_point(targetSound)
	
	if(distanceToSoundx > 20):
		move(direction, true)
		flash_light.rotation = directionToSound
	else:
		move(0, true)
		flash_light.rotation = sin(Time.get_unix_time_from_system())*PI/2-PI/2

@rpc("any_peer", "reliable", "call_local")
func removeLimb(limb:RigidBody2D):
	physicsLimbs.erase(limb)
	walkingLimbs.erase(limb)
	gunHoldingLimbs.erase(limb)
	livingLimbs.erase(limb)
	hearingLimbs.erase(limb)
	mainHoldingLimbs.erase(limb)

@rpc("any_peer", "reliable", "call_local")
func makeSound(location, volume):
	var sound:Area2D = SOUND.instantiate()
	sound.global_position = location
	sound.volume = volume
	get_parent().add_child(sound)

func takeDamage(damage):
	currentState = states.hostile
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

func findWebs():
	if(lastSeenWeb != Vector2.ZERO):
		currentState = states.getRidOfWebs

func avoidWebs():
	var bodies = awarness_area.get_overlapping_bodies()
	var webSeen = false
	for body in bodies:
		if(body.is_in_group("canStickToWeb")):
			#isBodyInSight = Geometry2D.is_point_in_polygon(to_local(body.global_position).rotated(-flash_light.global_rotation), sight.polygon)
			#print("see body is frozen: " + str(body.frozen)+  " : " + str(body))
			if(body.frozen):
				if(lastSeenWeb == Vector2.ZERO):
					currentState = states.callingForBackup
				lastSeenWeb = body.frozenPosition
				webSeen = true
				break
	if(!webSeen):
		lastSeenWeb = Vector2.ZERO
	

func aimWeapon(target):
	if(weapon == null):
		return
	
	var directionTotarget = global_position.angle_to_point(target)
	flash_light.rotation = directionTotarget
	
	$TargetRight.global_position = target
	$TargetLeft.global_position = weapon.otherHand.global_position

func shootWeapon():
	if(weapon == null || mainHoldingLimbs.size() == 0):
		return
	
	weapon.shoot.rpc()

func move(direction, walking):
	if(walkingLimbs.size() == 0):
		direction = 0
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
		if($"../AnimationPlayer".is_playing()):
			$"../AnimationPlayer".play("RESET")
	for limb:RigidBody2D in walkingLimbs:
		if limb.get_colliding_bodies().size() > 0:
			if(walking):
				velocity.x = direction*50
			else:
				velocity.x = direction*200

func processLimbs(delta):
	var i = 0
	stuckLimb = null
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
		
		if(position_difference.distance_to(Vector2.ZERO) > 300):
			limb.removeSelfFromBody.rpc()
		
		if(limb.frozen):
			currentState = states.stuck
			stuckLimb = limb
		
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
