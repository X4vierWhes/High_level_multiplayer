extends Node2D

@export var username_label: RichTextLabel
@onready var msgs: TextEdit = $CanvasLayer/Control/Control/msgs
@onready var msg: LineEdit = $CanvasLayer/Control/Control/msg
func _ready() -> void:
	print("Carregou a cena localmente. Notificando lobby...")
	Lobby.player_loaded.rpc()

func start_game() -> void:
	print("Start - Todos os jogadores estão sincronizados!")
	atualizar_interface_local()

func atualizar_interface_local() -> void:
	var meu_id = multiplayer.get_unique_id()
	
	if meu_id == 1:
		if 1 in Lobby.players:
			username_label.text = "Jogador Atual: " + Lobby.players[1]["name"]
	else:
		username_label.text = "Jogador Atual: " + Lobby.temporary_name

func _on_send_button_pressed() -> void:
	rpc("msg_rpc", username_label.text, msg.text)
	msg.text = ""

@rpc("any_peer", "call_local")
func msg_rpc(username: String, msg: String) -> void:
	msgs.text += str( username + " -> " + msg + "\n")
