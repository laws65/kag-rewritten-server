extends Node

var network = NetworkedMultiplayerENet.new()
var port = 28574
var max_players = 20
var player_state_collection = {}

var map = []
func _ready() -> void:
	start_server()
	for x in 20:
		map.append([])
		for y in 20:
			map[x].append(rand_range(0, 8))


func start_server() -> void:
	network.create_server(port, max_players)
	get_tree().set_network_peer(network)
	print("Server started")
	print("Listening on port " + str(port))
	
	network.connect("peer_connected", self, "on_peer_connected")
	network.connect("peer_disconnected", self, "on_peer_disconnected")


func on_peer_connected(player_id) -> void:
	print(str(player_id) + " has connected. (" + network.get_peer_address(player_id) + ")")
	rpc_id(0, "spawn_new_player", player_id)
	rpc_id(player_id, "load_map", "asdf", map)


func on_peer_disconnected(player_id) -> void:
	print(str(player_id) + " has disconnected. (" + network.get_peer_address(player_id) + ")")
#	if has_node(str(player_id)):
#		get_node(str(player_id)).queue_free()
	player_state_collection.erase(player_id)
	rpc_id(0, "despawn_player", player_id)


remote func recieve_player_state(player_state) -> void:
	var player_id = get_tree().get_rpc_sender_id()
	if player_state_collection.has(player_id):
		if player_state_collection[player_id]["T"] < player_state["T"]: # checks if player state is latest
			player_state_collection[player_id] = player_state # replaces player state
	else:
		player_state_collection[player_id] = player_state # adds player state to collection


func send_world_state(world_state) -> void: # called from stateprocessing.gd
	rpc_unreliable_id(0, "recieve_world_state", world_state)


remote func fetch_server_time(client_time) -> void:
	var player_id = get_tree().get_rpc_sender_id()
	rpc_id(player_id, "return_server_time", OS.get_system_time_msecs(), client_time)


remote func determine_latency(client_time) -> void:
	var player_id = get_tree().get_rpc_sender_id()
	rpc_id(player_id, "return_latency", client_time)
