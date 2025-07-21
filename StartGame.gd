extends Button
var level = "res://Levels/Level1.tscn"

func _process(delta: float) -> void:
	if(Multiplayer.is_host):
		show()
	else:
		hide()

func _on_button_up() -> void:
	if(!Multiplayer.is_host):
		return
	Multiplayer.inGame = true
	$"../..".changeLevel.rpc(multiplayer.get_unique_id(), level)
