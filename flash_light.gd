extends Node2D

@export var parent:Node2D

func _process(delta: float) -> void:
	if(parent.walkingDirection != 0):
		scale.x = parent.walkingDirection
