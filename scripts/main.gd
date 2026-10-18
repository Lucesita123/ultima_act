extends Node2D

@onready var player = $player
@onready var game_hud = $GameHUD


func _ready() -> void:
	player.health_changed.connect(game_hud.update_health)
	game_hud.update_health(player.health, player.max_health)
