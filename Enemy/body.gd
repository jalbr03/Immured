extends RigidBody2D


@export var limbAbilitys:Array[Globals.abilities]
var strengthMultiplyer:float = 1
var limbHP = 2
var frozen = false
var frozenPosition:Vector2

@rpc("any_peer", "reliable", "call_local")
func takeDamage(damage):
	if($"../Skeleton2D" == null):
		return
	$"../Skeleton2D".takeDamage(damage)
	limbHP -= damage
	if(limbHP <= 0):
		$"../Skeleton2D".removeLimb.rpc(self)
		reparent(get_parent().get_parent())

func _physics_process(delta: float) -> void:
	if(frozen):
		var directionPosition = frozenPosition - global_position
		linear_velocity = directionPosition*100

@rpc("any_peer", "reliable", "call_local")
func freezeLimb(freezePosition):
	frozen = true
	frozenPosition = freezePosition
