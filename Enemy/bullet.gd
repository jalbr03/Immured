extends Node2D

@export var damage = 1
@onready var line: Line2D = $Line2D
@onready var ray_cast: RayCast2D = $RayCast2D
@onready var hurt_collision: CollisionShape2D = $Area2D/hurtCollision


func _ready() -> void:
	ray_cast.force_raycast_update()
	line.add_point(Vector2.ZERO)
	var endPoint = to_global(ray_cast.target_position)
	if(ray_cast.is_colliding()):
		endPoint = ray_cast.get_collision_point()
	hurt_collision.scale.x = global_position.distance_to(endPoint)
	line.add_point(to_local(endPoint))

func _process(delta: float) -> void:
	line.modulate.a -= 0.02
	
	if(line.modulate.a <= 0):
		queue_free()


func _on_area_2d_body_entered(body: Node2D) -> void:
	if(!body.is_in_group("canTakeDamage")):
		return
	body.takeDamage(damage)
