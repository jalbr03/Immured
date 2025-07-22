class_name Monster
extends CharacterBody2D

var speed : int = 200

const GRAVITY = 100

@onready var game: Game = get_parent()

func _enter_tree():
	set_multiplayer_authority(int(str(name)))

func _ready():
	$VBoxContainer/PlayerName.text = Multiplayer.localPlayerName
	if !is_multiplayer_authority():
		$ColorRect.modulate = Color.RED

func _physics_process(delta: float) -> void:
	if(!is_multiplayer_authority()):
		return
	var input : Vector2 = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	
	velocity.x = input.x*speed
	
	if($RayCast2D.is_colliding()):
		velocity.y -= (10/$RayCast2D.get_collision_point().distance_to(global_position))*1000
		velocity.y *= 0.9
	
	velocity.y += GRAVITY
	
	move_and_slide()
	
