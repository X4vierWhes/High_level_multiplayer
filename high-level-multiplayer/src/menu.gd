extends Control

@export var ip_input: LineEdit
@onready var init: Button = $BoxContainer/VBoxContainer/init


func _ready() -> void:
	init.disabled = true

func _on_host_pressed() -> void:
	var err = Lobby.create_game()
	if err:
		print("Erro ao criar servidor: ", err)
	else:
		print("Servidor criado! Aguardando jogadores...")
		#Lobby.load_game.rpc("res://src/Game.tscn")
		init.disabled = false


func _on_join_pressed() -> void:
	var ip = ip_input.text if ip_input and not ip_input.text.is_empty() else "127.0.0.1"
	var err = Lobby.join_game(ip)
	if err:
		print("Erro ao conectar: ", err)
	else:
		print("Conectando ao servidor...")


func _on_init_pressed() -> void:
	print("Host clicou para iniciar! Mudando a cena de todos os jogadores...")
	Lobby.load_game.rpc("res://src/Game.tscn")
