extends RigidBody2D


@export var limbAbilitys:Array[Globals.abilities]
var strengthMultiplyer:float = 1
var limbHP = 2
var frozen = false
var frozenPosition:Vector2

func takeDamage(damage):
	if($"../Skeleton2D" == null):
		return
	$"../Skeleton2D".takeDamage(damage)
	limbHP -= damage
	if(limbHP <= 0):
		$"../Skeleton2D".removeLimb(self)
		reparent(get_parent().get_parent())

func _physics_process(delta: float) -> void:
	if(frozen):
		var directionPosition = frozenPosition - global_position
		linear_velocity = directionPosition*100
	#apply_force(global_position.direction_to(constrainTo.global_position)*500*global_position.distance_to(constrainTo.global_position))
	#rotation = lerp_angle(rotation, constrainTo.rotation, 1)
	#global_position = lerp(global_position, constrainTo.global_position, 1)
	#apply_central_force(global_position.direction_to(constrainTo.global_position)*10000)
