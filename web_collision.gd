extends Area2D

var fozenBodies:Array = []
var HP = 10

func _on_body_entered(body: Node2D) -> void:
	if(body.is_in_group("canStickToWeb")):
		if(fozenBodies.find(body, 0) == -1):
			fozenBodies.append(body)
			body.freezeLimb.rpc(body.global_position)

func _process(delta: float) -> void:
	for area in get_overlapping_areas():
		if(area.is_in_group("Damage")):
			HP -= 1
			area.queue_free()
			if(HP <= 0):
				destroyWeb()
			
func destroyWeb():
	for body in fozenBodies:
		if(body.is_in_group("canStickToWeb")):
			body.unFreezeLimb.rpc()
	
	get_parent().queue_free()
	queue_free()
#func _on_area_entered(area: Area2D) -> void:
	
