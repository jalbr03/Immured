extends Area2D

func _on_body_entered(body: Node2D) -> void:
	if(body.is_in_group("canStickToWeb")):
		body.freezeLimb.rpc(body.global_position)
		#body.frozen = true
		#body.frozenPosition = body.global_position
		
