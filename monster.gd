class_name Monster
extends CharacterBody2D

var speed : int = 200

const GRAVITY = 50
var jumpStrength = 1000
var jumping = false

@onready var floorRayCast = $FloorRayCast
@onready var floor_normal_ray_cast: RayCast2D = $FloorNormalRayCast
@onready var floor_normal_ray_cast_2: RayCast2D = $FloorNormalRayCast2

@onready var legRight = preload("res://leg_right.tscn")
@onready var legLeft = preload("res://leg_left.tscn")
var legs

@onready var game: Game = get_parent()

func _enter_tree():
	set_multiplayer_authority(int(str(name)))

func _ready():
	$VBoxContainer/PlayerName.text = Multiplayer.localPlayerName
	for i in range(2):
		var leg1:Node2D = legRight.instantiate()
		leg1.position = Vector2.ZERO
		leg1.position.x += i*10
		$Legs.add_child(leg1)
		var leg2:Node2D = legLeft.instantiate()
		leg2.position = Vector2.ZERO
		leg2.position.x -= i*10
		$Legs.add_child(leg2)
	
	legs = $Legs.get_children()
	if !is_multiplayer_authority():
		$ColorRect.modulate = Color.RED
		$Camera2D.enabled = false
		for leg in legs:
			leg.legEnabled = false

func _physics_process(delta: float) -> void:
	var floorNormal1:Vector2 = floor_normal_ray_cast.get_collision_point()
	var floorNormal2:Vector2 = floor_normal_ray_cast_2.get_collision_point()
	
	rotateToWall(floorNormal1, floorNormal2)
	if(!is_multiplayer_authority()):
		return
	var inputAxis = Input.get_axis("Left", "Right")
	var input : Vector2 = Vector2(inputAxis, 0)
	input = input.rotated(rotation)
	var jump = Input.is_action_just_pressed("Jump")
	
	for leg in legs:
		leg.inputDirection = inputAxis
	
	if(floorRayCast.is_colliding()):
		velocity += (input*speed-velocity)/10
		var direction: Vector2 = floorRayCast.global_position.direction_to(floorRayCast.get_collision_point()).normalized()
		velocity -= direction*(20/floorRayCast.get_collision_point().distance_to(global_position))*100
		velocity += direction*30
		
		if(jump):
			velocity += direction.rotated(PI)*jumpStrength
			jumping = true
	else:
		jumping = false
		rotation -= (rotation)/10
		velocity.y += GRAVITY
	
	move_and_slide()

func rotateToWall(floorNormal1, floorNormal2):
	if(!floorRayCast.is_colliding()):
		return
	
	var floorDirection = floorNormal1.direction_to(floorNormal2).normalized()
	
	rotation = lerp_angle(rotation, floorDirection.angle(),0.1)
