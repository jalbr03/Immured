extends RigidBody2D


@export var limbAbilitys:Array[Globals.abilities]
var strengthMultiplyer:float = 1
var limbHP = 2
var frozen = false
var frozenPosition:Vector2 = Vector2.ZERO

func _process(delta: float) -> void:
	#print("limb is frozen: " + str(frozen))
	#frozen = frozen
	if(Input.is_action_just_pressed("ui_down")):
		frozen = true
		frozenPosition = global_position

@rpc("any_peer", "reliable", "call_local")
func takeDamage(damage):
	frozen = false
	if($"../Skeleton2D" == null):
		return
	$"../Skeleton2D".takeDamage(damage)
	limbHP -= damage
	if(limbHP <= 0):
		removeSelfFromBody.rpc()

@rpc("any_peer", "reliable", "call_local")
func removeSelfFromBody():
	frozen = false
	$"../Skeleton2D".removeLimb.rpc(self)
	reparent(get_parent().get_parent())

func _physics_process(delta: float) -> void:
	if(frozen):
		var directionPosition = frozenPosition - global_position
		linear_velocity = directionPosition*20

@rpc("any_peer", "reliable", "call_local")
func freezeLimb(freezePosition):
	frozen = true
	frozenPosition = freezePosition

@rpc("any_peer", "reliable", "call_local")
func unFreezeLimb():
	frozen = false
	frozenPosition = Vector2.ZERO
