extends RigidBody2D


@export var limbAbilitys:Array[Globals.abilities]

func _physics_process(delta: float) -> void:
	pass
	#apply_force(global_position.direction_to(constrainTo.global_position)*500*global_position.distance_to(constrainTo.global_position))
	#rotation = lerp_angle(rotation, constrainTo.rotation, 1)
	#global_position = lerp(global_position, constrainTo.global_position, 1)
	#apply_central_force(global_position.direction_to(constrainTo.global_position)*10000)
