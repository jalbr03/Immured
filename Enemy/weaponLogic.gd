extends Node2D

@export var otherHand:Marker2D
@export var requoil = 1
var gunHolder:Node2D
var mainHoldingHand:Node2D
@export var maxReloadTime = 0.5
@export var bullet: PackedScene
var ReloadTime = 0

func _process(delta: float) -> void:
	if(mainHoldingHand == null):
		return
	global_position = mainHoldingHand.global_position
	scale.y = sign(global_position.x-gunHolder.global_position.x)
	rotation = mainHoldingHand.global_rotation+PI/2
	if(ReloadTime > 0):
		ReloadTime -= delta

@rpc("any_peer", "reliable", "call_local")
func shoot():
	if(ReloadTime > 0):
		return
	
	var shotBullet:Node2D = bullet.instantiate()
	shotBullet.position = global_position
	shotBullet.rotation = rotation
	get_tree().root.add_child(shotBullet)
	
	ReloadTime = maxReloadTime
	var arm:RigidBody2D = mainHoldingHand.get_parent()
	arm.apply_force(Vector2(cos(rotation+PI/2), sin(rotation+PI/2))*-requoil, global_position)
