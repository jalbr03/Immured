extends Node2D

@export var parent:Node2D

#func _process(delta: float) -> void:
	#if(parent.walkingDirection != 0):
		#if(parent.walkingDirection < 0):
			#rotation = PI
		#else:
			#rotation = 0
