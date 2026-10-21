extends Control

@onready var new_game_button: Button = \
	$CenterContainer/PanelContainer/VBoxContainer/NewGameButton
@onready var load_game_button: Button = \
	$CenterContainer/PanelContainer/VBoxContainer/LoadGameButton
@onready var exit_button: Button = \
	$CenterContainer/PanelContainer/VBoxContainer/ExitButton
@onready var save_slots = $SaveSlots


func _ready() -> void:
	get_tree().paused = false

	new_game_button.pressed.connect(
		_on_new_game_pressed
	)

	load_game_button.pressed.connect(
		_on_load_game_pressed
	)

	exit_button.pressed.connect(
		_on_exit_pressed
	)


func _on_new_game_pressed() -> void:
	SaveManager.new_game()


func _on_load_game_pressed() -> void:
	save_slots.open_menu(
		SaveSlots.Mode.LOAD
	)


func _on_exit_pressed() -> void:
	get_tree().quit()
