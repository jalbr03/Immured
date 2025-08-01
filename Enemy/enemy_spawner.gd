extends Node2D

@export var enemyToSpawn:PackedScene
@export var weaponForEnemy:PackedScene

func _ready() -> void:
	$MultiplayerSpawner.spawn_function = spawnEnemy
	$MultiplayerSpawner.spawn(multiplayer.get_unique_id())
	$Sprite2D.visible = false

func spawnEnemy(pid):
	print("spawned")
	var enemy:Node2D = enemyToSpawn.instantiate()
	enemy.position = Vector2.ZERO
	var weapon = weaponForEnemy.instantiate()
	weapon.global_position = global_position
	enemy.weapon = weapon
	enemy.add_child(weapon)
	return enemy
