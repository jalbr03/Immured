extends Node2D
@export var weapon:Node2D
@export var gunHoldFrom:Node2D

func call_child_recursive(node: Node2D, f: Callable):
	f.call(node)
	for child in node.get_children():
		call_child_recursive(child, f)

func update_bone(bone: Node2D):
	if bone is PhysicalBone2D:
		bone.simulate_physics = true
		bone.freeze = true
		bone.freeze = false

func _ready():
	for child in $Skeleton2D.get_children():
		if child is PhysicalBone2D:
			call_child_recursive(child, update_bone)
	
	if(weapon != null):
		weapon.gunHolder = gunHoldFrom
		weapon.mainHoldingHand = $PB_upperArmRight/Hand
		$Skeleton2D.weapon = weapon
		get_parent().add_child(weapon)

func _process(delta: float) -> void:
	for player in Globals.players:
		if(player.global_position.distance_to($PB_torso.global_position) > 4000):
			visible = false
		else:
			visible = true
