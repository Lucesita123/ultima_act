extends Node2D

var crystals_collected: int = 0
var total_crystals: int = 0

@onready var crystal_label: Label = \
	$UI/HUD/CrystalLabel
@onready var player = $player
@onready var game_hud = $GameHUD


func _ready() -> void:
	var crystals := $crystals.get_children()

	total_crystals = crystals.size()
	player.health_changed.connect(game_hud.update_health)
	game_hud.update_health(player.health, player.max_health)


func _on_crystal_collected() -> void:
	crystals_collected += 1
	update_crystal_label()

	if crystals_collected >= total_crystals:
		print("¡Todos los cristales recolectados!")

func update_crystal_label() -> void:
	crystal_label.text = "Cristales: %d / %d" % [
		crystals_collected,
		total_crystals
	]
