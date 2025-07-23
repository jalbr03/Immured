class_name Monster
extends CharacterBody2D

var speed : int = 200

const GRAVITY = 50
var jumpStrength = 1000
var jumping = false
var currentWeb:Line2D = null

@onready var floorRayCast = $FloorRayCast
@onready var floor_normal_ray_cast: RayCast2D = $FloorNormalRayCast
@onready var floor_normal_ray_cast_2: RayCast2D = $FloorNormalRayCast2
@onready var web_cast: RayCast2D = $WebCast

@onready var web = preload("res://web.tscn")
@onready var legRight = preload("res://leg_right.tscn")
@onready var legLeft = preload("res://leg_left.tscn")
var legs

@onready var game: Game = get_parent()

func _enter_tree():
	set_multiplayer_authority(int(str(name)))

func _ready():
	floorRayCast.collide_with_areas = true
	floor_normal_ray_cast.collide_with_areas = true
	floor_normal_ray_cast_2.collide_with_areas = true
	web_cast.collide_with_areas = true
	
	$VBoxContainer/PlayerName.text = Multiplayer.localPlayerName
	for i in range(3):
		var leg1:Node2D = legRight.instantiate()
		leg1.position = Vector2.ZERO
		leg1.position.x += i*10
		leg1.legIndex = i
		$Legs.add_child(leg1)
		var leg2:Node2D = legLeft.instantiate()
		leg2.position = Vector2.ZERO
		leg2.position.x -= i*10
		leg2.legIndex = i+1
		$Legs.add_child(leg2)
	
	legs = $Legs.get_children()
	if !is_multiplayer_authority():
		$ColorRect.modulate = Color.RED
		$Camera2D.enabled = false

func _physics_process(delta: float) -> void:
	var floorNormal1:Vector2 = floor_normal_ray_cast.get_collision_point()
	var floorNormal2:Vector2 = floor_normal_ray_cast_2.get_collision_point()
	
	if(!is_multiplayer_authority()):
		return
	
	rotateToWall(floorNormal1, floorNormal2)
	
	var inputAxis = Input.get_axis("Left", "Right")
	var input : Vector2 = Vector2(inputAxis, 0)
	input = input.rotated(rotation)
	var jump = Input.is_action_just_pressed("Jump")
	
	var justPressedSlingWeb = Input.is_action_just_pressed("slingWeb") || Input.is_action_just_pressed("spinWeb")
	var pressingSlingWeb = Input.is_action_pressed("slingWeb")
	var pressingSpinWeb = Input.is_action_pressed("spinWeb")
	
	if(justPressedSlingWeb && web_cast.is_colliding() && currentWeb == null):
		createWeb.rpc(multiplayer.get_unique_id())
	
	if(pressingSlingWeb && currentWeb != null):
		var nextPoint = currentWeb.points[1]
		velocity += nextPoint/10
		look_at(currentWeb.globalPositions[1])
		rotation -= PI/2
	elif(pressingSpinWeb && currentWeb != null):
		pass
	
	if(!pressingSlingWeb && !pressingSpinWeb && currentWeb != null):
		setDownWeb.rpc(multiplayer.get_unique_id())
	
	web_cast.look_at(get_global_mouse_position())
	
	if(!pressingSlingWeb || currentWeb == null):
		movement(input, jump)
	
	move_and_slide()

func movement(input, jump):
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

func rotateToWall(floorNormal1, floorNormal2):
	if(!floorRayCast.is_colliding()):
		return
	
	var floorDirection = floorNormal1.direction_to(floorNormal2).normalized()
	
	rotation = lerp_angle(rotation, floorDirection.angle(),0.1)

@rpc("any_peer", "reliable", "call_local")
func createWeb(pid):
	var webObj:Line2D = web.instantiate()
	webObj.set_multiplayer_authority(pid)
	webObj.position = Vector2.ZERO
	webObj.add_point(Vector2.ZERO)
	webObj.add_point(to_local(web_cast.get_collision_point()))
	currentWeb = webObj
	add_child(webObj)

@rpc("any_peer", "reliable", "call_local")
func destroyWeb(pid):
	currentWeb.queue_free()
	currentWeb = null
	
@rpc("any_peer", "reliable", "call_local")
func setDownWeb(pid):
	currentWeb.reparent(get_parent())
	var webPos = currentWeb.global_position
	var targetPoint = web_cast.get_collision_point()
	var steps = 100
	for i in range(steps):
		print(currentWeb.global_position)
		currentWeb.global_position = lerp(webPos, targetPoint, float(i+1)/steps)
		currentWeb.updateWeb()
		if(currentWeb.global_position == targetPoint):
			break
	currentWeb.setWeb()
	currentWeb = null
