class_name Runner
extends CharacterBody2D

var speed : int = 20

@onready var game: Game = get_parent()

func _ready():
	#SceneReplicationConfig.REPLICATION_MODE_ALWAYS
	if !Multiplayer.is_host:
		$Sprite2D.modulate = Color.RED

func _physics_process(delta: float) -> void:
	if(!Multiplayer.is_host):
		return
	var input : Vector2 = Vector2(1, 0)
	
	velocity = input*speed
	
	move_and_slide()
	
