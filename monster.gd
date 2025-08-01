class_name Monster
extends CharacterBody2D

var speed : int = 300

const GRAVITY = 50
var jumpStrength = 1000
var jumping = false
var currentWeb:Line2D = null

var lastJawPos = Vector2.ZERO
@export var jawShake = false
@export var bitingObject:Node2D = null

@onready var floorRayCast:RayCast2D = $FloorRayCast
@onready var floor_normal_ray_cast: RayCast2D = $FloorNormalRayCast
@onready var floor_normal_ray_cast_2: RayCast2D = $FloorNormalRayCast2
@onready var web_cast: RayCast2D = $WebCast
@onready var web_cast_body_check: Area2D = $WebCastBodyCheck
@onready var target: Node2D = $Target
@onready var jaws: Node2D = $jaws
@onready var jaw_animation: AnimationPlayer = $jaws/jawAnimation
@onready var jawBottom: Polygon2D = $jaws/Polygon2D
@onready var jawTop: Polygon2D = $jaws/Polygon2D2
@onready var biting_hit_box: Area2D = $jaws/bitingHitBox
var bitingList:Array = []

@onready var web = preload("res://web.tscn")
@onready var legRight = preload("res://leg_right.tscn")
@onready var legLeft = preload("res://leg_left.tscn")
var legs
var canMove = true

var maxHP = 3
var HP = maxHP
@onready var respawnLocation = global_position

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
	var justReleasedSlingWeb = Input.is_action_just_released("slingWeb")
	var pressingSlingWeb = Input.is_action_pressed("slingWeb")
	var pressingSpinWeb = Input.is_action_pressed("spinWeb")
	var startBiting = Input.is_action_just_pressed("bite")
	var biting = Input.is_action_pressed("bite")
	var biteReleased = Input.is_action_just_released("bite")
	var pressingDown = Input.is_action_pressed("down")
	
	if(startBiting):
		var overlappingBodies:Array = $jaws/bitingHitBox.get_overlapping_bodies()
		if(!overlappingBodies.find(bitingObject, 0)):
			bitingObject = null
		jaw_animation.play("biting")
	if(biting):
		bite.rpc()
	else:
		if(biteReleased):
			bitingList.clear()
			bitingObject = null
		jaws.scale = lerp(jaws.scale, Vector2.ONE*0.6, 0.1)
		jaws.position = lerp(jaws.position, Vector2.ZERO, 0.1)
		jawBottom.position = lerp(jaws.position, Vector2(0, sin(Time.get_unix_time_from_system()*5)*100), 0.1)
		jawTop.position = lerp(jaws.position, Vector2.ZERO, 0.1)
		jawShake = false
	
	if(justPressedSlingWeb && web_cast.is_colliding() && currentWeb == null):
		createWeb.rpc(multiplayer.get_unique_id())
	
	if(pressingSlingWeb && currentWeb != null):
		var nextPoint = currentWeb.points[1]
		velocity += nextPoint/10
		look_at(currentWeb.globalPositions[1])
		rotation -= PI/2
	elif(pressingSpinWeb && currentWeb != null && !floorRayCast.is_colliding()):
		var nextPoint = currentWeb.points[1]
		if(nextPoint.y+global_position.y < global_position.y):
			velocity.x += nextPoint.x/10
			velocity.x *= 0.96
			if(!pressingDown):
				velocity.y = nextPoint.y/50
	
	if(justReleasedSlingWeb && !pressingSpinWeb && currentWeb != null):
		destroyWeb.rpc(multiplayer.get_unique_id())
		currentWeb = null
	
	if(!pressingSlingWeb && !pressingSpinWeb && currentWeb != null):
		reparentWeb.rpc(multiplayer.get_unique_id())
		setDownWeb()
		currentWeb = null
	
	web_cast.look_at(get_global_mouse_position())
	#web_cast.global_position = get_global_mouse_position()-global_position.direction_to(get_global_mouse_position())*10
	web_cast_body_check.global_position = web_cast.get_collision_point()
	target.global_position = lerp(target.global_position, web_cast.get_collision_point(), 0.1)
	
	if(!pressingSlingWeb || currentWeb == null):
		movement(input, jump, pressingDown, canMove)
	
	move_and_slide()

func movement(input, jump, pressingDown, canMove):
	if(is_on_floor()):
		velocity *= 0.9
	if(floorRayCast.is_colliding() && !pressingDown && canMove):
		velocity += (input*speed-velocity)/10
		var direction: Vector2 = floorRayCast.global_position.direction_to(floorRayCast.get_collision_point()).normalized()
		velocity -= direction*(20/clamp(floorRayCast.get_collision_point().distance_to(global_position), 10, INF))*100
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
func bite():
	if(bitingObject != null):
		jawBottom.position = lerp(jawBottom.position, Vector2.ZERO, 0.5)
		jawTop.position = lerp(jawTop.position, Vector2.ZERO, 0.5)
	if(!jawShake && jawBottom.position.y < 1 && !jaw_animation.is_playing()):
		jawShake = true
	
	if(jawShake):
		jaws.position.x = lerp(jaws.position.x, get_local_mouse_position().x/10, 0.5)
		if(bitingObject != null && bitingObject.has_method("takeDamage")):
			#var bodyToBit = bitingObject
			#bitingObject.takeDamage(0.01)
			var directionToJaws = global_position - bitingObject.global_position + jaws.position.rotated(rotation)
			bitingObject.linear_velocity = directionToJaws*50
			var shakeSpeed = lastJawPos.distance_to(jaws.position)
			if(shakeSpeed > 20):
				bitingObject.takeDamage(0.03)
		
	
	jaws.scale = lerp(jaws.scale, Vector2.ONE, 0.1)
	lastJawPos = jaws.position
	#if(!jaw_animation.is_playing() && !jawShake):
		#jaw_animation.play("biting")
	#if(jawShake):
		##jaws.position.x = lerp(jaws.position.x, sin(Time.get_unix_time_from_system()*30)*100, 0.5)
		#jaws.position.x = lerp(jaws.position.x, get_local_mouse_position().x/10, 0.5)

@rpc("any_peer", "reliable", "call_local")
func createWeb(pid):
	var webObj:Line2D = web.instantiate()
	webObj.set_multiplayer_authority(pid)
	webObj.position = Vector2.ZERO
	webObj.add_point(Vector2.ZERO)
	webObj.add_point(to_local(web_cast.get_collision_point()))
	if(web_cast_body_check.get_overlapping_bodies().size() > 0):
		webObj.objectConectedTo = web_cast_body_check.get_overlapping_bodies()[0]
	currentWeb = webObj
	add_child(webObj)

@rpc("any_peer", "reliable", "call_local")
func destroyWeb(pid):
	currentWeb.queue_free()
	currentWeb = null
	
@rpc("any_peer", "reliable", "call_local")
func reparentWeb(pid):
	currentWeb.reparent(get_parent())
	currentWeb.settingDown = true

func setDownWeb():
	var webPos = currentWeb.global_position
	var targetPoint = web_cast.get_collision_point()
	var steps = 100
	for i in range(steps):
		currentWeb.global_position = lerp(webPos, targetPoint, float(i+1)/steps)
		currentWeb.updateWeb()
		if(currentWeb.global_position == targetPoint):
			break

func takeDamage(damage):
	HP -= damage
	if(HP <= 0):
		respawn()

func respawn():
	position = respawnLocation
	HP = maxHP
	if(currentWeb != null):
		destroyWeb.rpc(multiplayer.get_unique_id())
		currentWeb = null
	

func _on_biting_hit_box_body_entered(body: Node2D) -> void:
	if(body is RigidBody2D && body.is_in_group("canTakeDamage") && !jawShake):
		if(!bitingList.has(body)):
			bitingList.append(body)
		
		bitingObject = bitingList[0]


func _on_biting_hit_box_body_exited(body: Node2D) -> void:
	if(body is RigidBody2D && body.is_in_group("canTakeDamage") && !jawShake):
		bitingList.erase(body)
