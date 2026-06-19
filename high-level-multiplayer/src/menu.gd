extends Control

@export var ip_input: LineEdit
@onready var init: Button = $BoxContainer/VBoxContainer/init
@onready var join: Button = $BoxContainer/VBoxContainer/join
@onready var host: Button = $BoxContainer/VBoxContainer/host

const ip: String = "127.0.0.1"

func _ready() -> void:
	init.disabled = true

func _on_host_pressed() -> void:
	host.disabled = true
	join.disabled = true
	var username = ip_input.text if ip_input and not ip_input.text.is_empty() else "Host_Anonymous"
	
	var err = Lobby.create_game_with_name(username)
	if err:
		print("Erro ao criar servidor: ", err)
		host.disabled = false
		join.disabled = false
	else:
		print("Servidor criado! Aguardando jogadores...")
		init.disabled = false


func _on_join_pressed() -> void:
	join.disabled = true
	host.disabled = true
	var username = ip_input.text if ip_input and not ip_input.text.is_empty() else "anonymous"
	
	Lobby.temporary_name = username
	
	var err = Lobby.join_game(ip)
	if err:
		print("Erro ao conectar: ", err)
		host.disabled = false
		join.disabled = false
	else:
		print("Conectando ao servidor...")

func _on_init_pressed() -> void:
	print("Host clicou para iniciar! Mudando a cena de todos os jogadores...")
	Lobby.load_game.rpc("res://src/Game.tscn")
