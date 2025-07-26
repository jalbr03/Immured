extends Node2D

@export var otherHand:Marker2D
@export var requoil = 100
var gunHolder:Node2D
var mainHoldingHand:Node2D
@export var maxReloadTime = 1
var ReloadTime = 0

func _process(delta: float) -> void:
	global_position = mainHoldingHand.global_position
	scale.y = sign(global_position.x-gunHolder.global_position.x)
	rotation = mainHoldingHand.global_rotation+PI/2
	if(ReloadTime > 0):
		ReloadTime -= delta

func shoot():
	if(ReloadTime > 0):
		return
	ReloadTime = maxReloadTime
	var arm:RigidBody2D = mainHoldingHand.get_parent()
	arm.apply_force(Vector2(cos(rotation+PI/2), sin(rotation+PI/2))*-requoil, global_position)
