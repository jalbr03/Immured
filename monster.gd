class_name Monster
extends CharacterBody2D

var speed : int = 200

@onready var game: Game = get_parent()

func _enter_tree():
	set_multiplayer_authority(int(str(name)))

func _ready():
	if !is_multiplayer_authority():
		$ColorRect.modulate = Color.RED

func _physics_process(delta: float) -> void:
	if(!is_multiplayer_authority()):
		return
	var input : Vector2 = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	
	velocity = input*speed
	
	move_and_slide()
	
