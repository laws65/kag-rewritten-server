extends Node

var network = NetworkedMultiplayerENet.new()
var port = 28574
var max_players = 20
var player_state_collection = {}

var map_data = []

export (String, FILE, "*.png") var current_map

var player_data = {}
enum Teams {
	BLUE,
	RED,
}

enum GameClasses {
	KNIGHT,
	ARCHER,
}

var spawnpoints = {
	Teams.BLUE: Vector2.ZERO,
	Teams.RED: Vector2.ZERO,
}


func _ready() -> void:
	start_server()
	map_data = get_node("MapLoader").load_map(current_map)


func start_server() -> void:
	network.create_server(port, max_players)
	get_tree().set_network_peer(network)
	print("Server started")
	print("Listening on port " + str(port))
	
	network.connect("peer_connected", self, "on_peer_connected")
	network.connect("peer_disconnected", self, "on_peer_disconnected")


func on_peer_connected(player_id) -> void:
	print(str(player_id) + " has connected. (" + network.get_peer_address(player_id) + ")")
	for player in player_data.keys():
		rpc_id(player_id, "spawn_player", player, player_data[player])
	player_data[player_id] = {"team": -1, "class": -1, "spawnpoint": Vector2()}
	assign_team(player_id)
	assign_class(player_id)
	assign_spawnpoint(player_id)
	rpc_id(0, "spawn_player", player_id, player_data[player_id])
	rpc_id(player_id, "load_map", current_map.get_basename(), map_data)


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


func assign_team(player_id: int) -> void:
	player_data[player_id]["team"] = Teams.RED


func assign_class(player_id: int) -> void:
	player_data[player_id]["class"] = GameClasses.KNIGHT


func assign_spawnpoint(player_id: int) -> void:
	var team = player_data[player_id]["team"]
	var spawnpoint = spawnpoints[team]
	player_data[player_id]["spawnpoint"] = spawnpoint
