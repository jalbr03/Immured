extends Node

signal noray_connected

const NORAY_ADDRESS = "tomfol.io"
const NORAY_PORT = 8890

var connectionFailed = false
var inGame = false
var is_host = false
var external_oid = ""

var clients = []
var clientNames := {}
var localPlayerName = "player"

func addClient(client):
	clients.append(client)
	clientNames[client] = str(client)

#func removeClient(client):
	#clients.remove_at(clients.find(client))
	#clientNames.erase(client)

func getClientIndex(index):
	if(is_host):
		return clientNames[clientNames.keys()[index]]
	
func setClientIndex(index, value):
	
	if(is_host):
		clientNames[clientNames.keys()[index]] = value

func _ready():
	Noray.on_connect_to_host.connect(on_noray_connected)
	Noray.on_connect_nat.connect(handle_nat_connection)
	Noray.on_connect_relay.connect(handle_relay_connection)
	
	Noray.connect_to_host(NORAY_ADDRESS, NORAY_PORT)

func on_noray_connected():
	print("Connected to Noray server")
	
	Noray.register_host()
	await Noray.on_pid
	await Noray.register_remote()
	noray_connected.emit()

func host():
	print("Hosting")
	
	var peer = ENetMultiplayerPeer.new()
	peer.create_server(Noray.local_port)
	multiplayer.multiplayer_peer = peer
	is_host = true

func join(oid):
	Noray.connect_nat(oid)
	external_oid = oid

func handle_nat_connection(address, port):
	var err = await connect_to_server(address, port)
	
	if err != OK && !is_host:
		print("NAT failed, using relay")
		Noray.connect_relay(external_oid)
		err = OK
	
	return err

func handle_relay_connection(address, port):
	return await connect_to_server(address, port)

func connect_to_server(address, port):
	var err = OK
	
	if !is_host:
		var udp = PacketPeerUDP.new()
		udp.bind(Noray.local_port)
		udp.set_dest_address(address, port)
		
		err = await PacketHandshake.over_packet_peer(udp)
		udp.close()
		
		if err != OK:
			if err != ERR_BUSY:
				print("Handshake failed")
				return err
		else:
			print("Handshake success")
		
		var peer = ENetMultiplayerPeer.new()
		err = peer.create_client(address, port, 0, 0, 0, Noray.local_port)
		
		if err != OK:
			connectionFailed = true
			return err
		
		multiplayer.multiplayer_peer = peer
		
		return OK
	else:
		if(!inGame):
			err = await PacketHandshake.over_enet(multiplayer.multiplayer_peer.host, address, port)
	
	return err
