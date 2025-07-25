extends Node2D

@export var hand1:Marker2D
@export var hand2:Marker2D
@export var requoil = 100
var gunHolder:Node2D
var mainHoldingHand:Node2D

func _process(delta: float) -> void:
	global_position = mainHoldingHand.global_position
	scale.y = sign(global_position.x-gunHolder.global_position.x)
	rotation = mainHoldingHand.global_rotation+PI/2
	
func shoot():
	var arm:RigidBody2D = mainHoldingHand.get_parent()
	arm.apply_force(Vector2(cos(rotation+PI/2), sin(rotation+PI/2))*-requoil*10, global_position)
