extends Node2D

@onready var username_label: RichTextLabel = $CanvasLayer/Control/Control/username
@onready var msgs: TextEdit = $CanvasLayer/Control/Control/msgs
@onready var nova_msg: LineEdit = $CanvasLayer/Control/Control/nova_msg
func _ready() -> void:
	print("Carregou a cena localmente. Notificando lobby...")
	username_label.text = "[wave connected=0] {username} [/wave]".format({"username": Lobby.players[multiplayer.get_unique_id()]["name"]})


func _on_send_button_pressed() -> void:
	var crypto := Crypto.new()
	var payload:String = "{\"username\": \"%s\", \"msg\": \"%s\" }" % [Lobby.players[multiplayer.get_unique_id()]["name"], nova_msg.text]
	for i in multiplayer.get_peers():
		print('mensagem enviada a %s' % i)
		var encrypted = crypto.encrypt(Lobby.players[i]["key"], payload.to_utf8_buffer())
		rpc_id(i, "msg_rpc", encrypted)
	append_message(Lobby.players[multiplayer.get_unique_id()]["name"], nova_msg.text)
	nova_msg.text = ""

@rpc("any_peer")
func msg_rpc(data: PackedByteArray) -> void:
	var crypto:=Crypto.new()
	var decrypted:String = crypto.decrypt(Lobby.key_pair, data).get_string_from_utf8()
	var payload:Dictionary = JSON.parse_string(decrypted)
	append_message(payload["username"], payload["msg"])

func append_message(username:String, msg:String) -> void:
	msgs.text += str(username + " -> " + msg + "\n")
