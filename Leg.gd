extends Node2D

@export var nextStepPoint:Vector2
@export var legDirection:int
@export var inputDirection = 0
var lastStepPoint:Vector2
var currentStepPoint:Vector2

var stepDist = 130
var legIndex = 0
var stepDelay = 0
var maxStepDelay

@onready var lastPosition = global_position

var animateLeg = false
var animateTime = 0
var animationSpeed = 0.005
var animateToPoint:Vector2
enum floorCastStates {castOut, castIn, castInLong}
var floorCastState = floorCastStates.castOut

func _ready() -> void:
	nextStepPoint = $Target.global_position
	currentStepPoint = $Target.global_position
	lastStepPoint = $Target.global_position
	maxStepDelay = legIndex*100
	
	$FloorCast.collide_with_areas = true
	#if(!is_multiplayer_authority()):
		#get_modification_stack().enabled = false

func _process(delta: float) -> void:
	#if(!legEnabled):
		#return
	$Target.global_position = currentStepPoint
	var input = (global_position - lastPosition)#Input.get_axis("Left", "Right")
	
	input = input.rotated(-global_rotation)
	if(input.x != 0):
		inputDirection = sign(input.x)
		#print(input)
	
	if(legDirection == inputDirection):
		$FloorCast.position.x = stepDist*legDirection*2
		$FloorCast.target_position.x = -stepDist*legDirection*2
		$FloorCast.target_position.y = 200
		#match floorCastState:
			#floorCastStates.castOut:
				#$FloorCast.target_position.x = stepDist*legDirection*1.5
				#if(!$FloorCast.is_colliding()):
					#floorCastState = floorCastStates.castIn
			#floorCastStates.castIn:
				#$FloorCast.position.x = stepDist*legDirection
				#$FloorCast.target_position.x = -stepDist*legDirection*1.5
				#if(!$FloorCast.is_colliding()):
					#floorCastState = floorCastStates.castInLong
			#floorCastStates.castInLong:
				#$FloorCast.position.x = stepDist*legDirection
				#$FloorCast.target_position.x = -stepDist*legDirection*2
				#$FloorCast.target_position.y = 200
	else:
		floorCastState = floorCastStates.castOut
		$FloorCast.position.x = 0
		$FloorCast.target_position.x = 0
		$FloorCast.target_position.y = 100
	
	nextStepPoint = $FloorCast.get_collision_point()
	
	if(currentStepPoint.distance_to(nextStepPoint) > stepDist && !animateLeg):
		stepDelay -= 1
		if(stepDelay <= 0):
			animateLeg = true
			animateToPoint = nextStepPoint
	else:
		stepDelay = maxStepDelay
	if(animateLeg):
		var animatedStep = animateToPoint
		var animatedLastStep = lastStepPoint
		var upVector = (Vector2.UP.rotated(global_rotation)*100)
		if(animateTime < 0.5):
			animatedStep = animateToPoint+upVector
		else:
			animatedLastStep = lastStepPoint+upVector
			animatedStep = animateToPoint
		currentStepPoint = lerp(animatedLastStep, animatedStep, animateTime)
		
		animateTime += animationSpeed
		if(animateTime >= 1):
			animateLeg = false
			animateTime = 0
			lastStepPoint = currentStepPoint
	
	if(lastPosition.distance_to(global_position) > 0.5):
		lastPosition = global_position
