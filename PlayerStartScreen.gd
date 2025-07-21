extends TextEdit

@export var selfIndex = 0

func _ready():
	if(is_multiplayer_authority()):
		var players = 0
		print(get_parent().get_children())
		for child in get_parent().get_children():
			if child.name.contains("PlayerName"):
				players += 1
		text += str(players)
		position.y = 40*players
	
	if !is_multiplayer_authority():
		modulate = Color.RED
		editable = false

func _process(delta: float) -> void:
	Multiplayer.setClientIndex(selfIndex, text)
