extends Camera2D

func _process(delta: float) -> void:
	if(Input.is_action_pressed("bite")):
		position = lerp(position, Vector2.ZERO, 0.1)
	else:
		position = lerp(position, get_local_mouse_position()/2, 0.1)
