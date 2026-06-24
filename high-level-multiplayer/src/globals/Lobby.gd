extends Node

signal player_connected(peer_id, player_info)
signal player_disconnected(peer_id)
signal server_disconnected

const PORT = 7000
const DEFAULT_SERVER_IP = "127.0.0.1"
const MAX_CONNECTIONS = 20

const KEY_MANAGER_SERVICE_URL:String = "http://localhost:8080/keymanager"
var key_pair:CryptoKey
var authority_key:CryptoKey

var players = {}
var temporary_name: String = "Name"
var players_loaded = 0

var http:HTTPRequest

func _ready():
	http = HTTPRequest.new()
	add_child(http)
	multiplayer.peer_connected.connect(_on_player_connected)
	multiplayer.peer_disconnected.connect(_on_player_disconnected)
	multiplayer.connected_to_server.connect(_on_connected_ok)
	multiplayer.connection_failed.connect(_on_connected_fail)
	multiplayer.server_disconnected.connect(_on_server_disconnected)

func create_game_with_name(host_name: String):
	var peer = ENetMultiplayerPeer.new()
	var error = peer.create_server(PORT, MAX_CONNECTIONS)
	if error:
		return error
	multiplayer.multiplayer_peer = peer
	
	var crypto := Crypto.new()
	key_pair = crypto.generate_rsa(2048)
	players[1] = {"name": host_name, "key": key_pair}
	
	http.request(
		KEY_MANAGER_SERVICE_URL + "/key", 
		["content-Type: application/json"], 
		HTTPClient.METHOD_POST, 
		JSON.stringify({"userId": "SERVIDOR", "publicKey": key_pair.save_to_string(true)})
	)
	var responseFunction = func(
			_result: int, 
			_response_code: int, 
			_headers: PackedStringArray, 
			body: PackedByteArray):
				print("chave pública guardada no servidor de chaves")
				authority_key = CryptoKey.new()
				var json:Dictionary = JSON.parse_string(body.get_string_from_utf8())
				authority_key.load_from_string(json["authorityPublicKey"], true)
	
	http.request_completed.connect(responseFunction)
	await http.request_completed
	http.request_completed.disconnect(responseFunction)

func join_game(client_name:String):
	temporary_name = client_name
	var peer = ENetMultiplayerPeer.new()
	var error = peer.create_client(DEFAULT_SERVER_IP, PORT)
	if error:
		return error
	
	var crypto := Crypto.new()
	key_pair = crypto.generate_rsa(2048)
	multiplayer.multiplayer_peer = peer
	
	http.request(
		KEY_MANAGER_SERVICE_URL + "/key", 
		["content-Type: application/json"], 
		HTTPClient.METHOD_POST, 
		JSON.stringify({"userId": multiplayer.get_unique_id(), "publicKey": key_pair.save_to_string(true)})
	)
	
	var responseFunction:Callable = func(
			_result: int, 
			response_code: int, 
			_headers: PackedStringArray, 
			body: PackedByteArray):
				if (response_code == 200): 
					authority_key = CryptoKey.new()
					var json:Dictionary = JSON.parse_string(body.get_string_from_utf8())
					authority_key.load_from_string(json["authorityPublicKey"], true)
				
	http.request_completed.connect(responseFunction)
	await http.request_completed
	http.request_completed.disconnect(responseFunction)

func remove_multiplayer_peer():
	multiplayer.multiplayer_peer = OfflineMultiplayerPeer.new()
	players.clear()

@rpc("authority", "call_local", "reliable")
func load_game(game_scene_path):
	if multiplayer.is_server():
		for i in multiplayer.get_peers():
			http.request(KEY_MANAGER_SERVICE_URL+"/key/" + str(i))
	else: http.request(KEY_MANAGER_SERVICE_URL+"/key/SERVIDOR")
	
	var responseFunction:Callable = func(_result, _response_code, _headers, body):
		var crypto := Crypto.new()
		var json = JSON.parse_string(body.get_string_from_utf8())
		var new_key := CryptoKey.new()
		new_key.load_from_string(json["publicKey"], true)
		crypto.verify(
			HashingContext.HASH_SHA256, 
			json["publicKey"].sha256_buffer(),
			json["signature"].sha256_buffer(), 
			authority_key) # ESTA FUNÇÃO CRIARÁ UMA EXCESSÃO CASO NÃO SEJA VÁLIDO
		players[(json["userId"] as int) if json["userId"] != "SERVIDOR" else 1]["key"] = new_key
	
	http.request_completed.connect(responseFunction)
	await http.request_completed
	http.request_completed.disconnect(responseFunction)
	
	get_tree().change_scene_to_file(game_scene_path)

func _on_player_connected(id):
	if multiplayer.is_server():
		_register_player.rpc_id(id, 1, players[1]["name"])

func _on_connected_ok():
	# Passa o ID próprio e o nome temporário (String) corrigido aqui
	players[multiplayer.get_unique_id()] = {"name": temporary_name, "key": key_pair}
	_register_player.rpc_id(1,multiplayer.get_unique_id(), temporary_name)

# Corrigido aqui: a função agora aceita String para o nome do jogador
@rpc("any_peer", "reliable")
func _register_player(id_do_jogador: int, nome_do_jogador:String):
	# Monta o dicionário de forma isolada na memória de quem recebe
	players[id_do_jogador] = {"name": nome_do_jogador}
	print("--- Registro de Rede --- ID: ", id_do_jogador, " | Nome: ", nome_do_jogador)
	player_connected.emit(id_do_jogador, players[id_do_jogador])
	
	#if multiplayer.is_server():
		#for id_conectado in players:
			#if id_conectado != 1 and id_conectado != payload["id_do_jogador"]:
				## Atualiza os outros clientes cruzando as informações
				#_register_player.rpc_id(id_conectado, payload["id_do_jogador"], payload["nome_do_jogador"])
				#_register_player.rpc_id(payload["id_do_jogador"], id_conectado, players[id_conectado]["name"])

func _on_player_disconnected(id):
	players.erase(id)
	player_disconnected.emit(id)

func _on_connected_fail():
	remove_multiplayer_peer()

func _on_server_disconnected():
	remove_multiplayer_peer()
	players.clear()
	server_disconnected.emit()
