extends Area2D

var volume = 1
var lifeTime = 1

func _ready() -> void:
	scale = Vector2.ONE * volume

func _process(delta: float) -> void:
	lifeTime -= delta
	
	if(lifeTime <= 0):
		queue_free()
