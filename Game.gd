class_name Game
extends Node

@onready var multiplayer_ui = $UI/Multiplayer
@onready var oid_lbl = $UI/Multiplayer/VBoxContainer/OID
@onready var oid_input = $UI/Multiplayer/VBoxContainer/OIDInput

@onready var runner = preload("res://runner.tscn")

const PLAYER = preload("res://monster.tscn")

const PLAYER_TEXTBOX = preload("res://player_name.tscn")

var peer = ENetMultiplayerPeer.new()
var players: Array[Monster] = []

func _ready():
	$MultiplayerSpawner.spawn_function = add_player
	$Level/PlayerTextSpawner.spawn_function = add_player_text_box
	
	await Multiplayer.noray_connected
	oid_lbl.text = Noray.oid

func _process(delta: float) -> void:
	if(Multiplayer.connectionFailed):
		Multiplayer.connectionFailed = false
		multiplayer_ui.show()
	#if(!Multiplayer.is_host):
		#return
	
	#if(Input.is_action_just_pressed("ui_accept")):
		#SpawnRunner.rpc(multiplayer.get_unique_id())


@rpc("authority", "call_local", "reliable")
func changeLevel(pid, NextLevel):
	get_child(0).queue_free()
	var level:Node2D = load(NextLevel).instantiate()
	level.set_multiplayer_authority(pid)
	level.global_position = Vector2.ZERO
	add_child(level)
	for client in Multiplayer.clients:
		$MultiplayerSpawner.spawn(client)

@rpc("authority", "call_local", "reliable")
func SpawnRunner(shooter_pid):
	var runnerObj : CharacterBody2D = runner.instantiate()
	runnerObj.set_multiplayer_authority(shooter_pid)
	runnerObj.position = Vector2(20, 20)
	add_child(runnerObj)

func _on_host_pressed():
	Multiplayer.host()
	
	multiplayer.peer_connected.connect(
		func(pid):
			print("Peer " + str(pid) + " has joined the game!")
			Multiplayer.addClient(pid)
			$Level/PlayerTextSpawner.spawn(pid)
	)
	
	Multiplayer.addClient(multiplayer.get_unique_id())
	$Level/PlayerTextSpawner.spawn(multiplayer.get_unique_id())
	multiplayer_ui.hide()

func _on_join_pressed():
	Multiplayer.join(oid_input.text)
	
	multiplayer_ui.hide()

func add_player_text_box(pid):
	var textBox = PLAYER_TEXTBOX.instantiate()
	#textBox.text += str(Multiplayer.clients.size())
	textBox.set_multiplayer_authority(pid)
	textBox.position = Vector2(20, 40*Multiplayer.clients.size())
	return textBox

func add_player(pid):
	var player = PLAYER.instantiate()
	player.name = str(pid)
	player.global_position = find_child("SpawnPoint", true, false).global_position
	players.append(player)
	return player

func _on_copy_oid_pressed():
	DisplayServer.clipboard_set(Noray.oid)
