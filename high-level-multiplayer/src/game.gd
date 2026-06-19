extends Node2D

func _ready():
	print("Carregou a cena localmente. Notificando lobby...")
	# Modo correto de invocar o RPC configurado na Godot 4
	Lobby.player_loaded.rpc()

func start_game():
	print("Start - Todos os jogadores estão sincronizados!")
