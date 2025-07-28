extends Area2D



func _on_body_entered(body: Node2D) -> void:
	if(body.is_in_group("canStickToWeb")):
		body.frozen = true
		body.frozenPosition = body.global_position
		
