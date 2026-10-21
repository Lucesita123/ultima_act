extends Node2D

@onready var interactive_area: Area2D = $InteractiveArea
var player_nearby: bool = false

func _ready() -> void:
	interactive_area.body_entered.connect(
		_on_body_entered
	)
	
	interactive_area.body_exited.connect(
		_on_body_exited
	)
	
func _process(delta: float) -> void:
	if player_nearby and Input.is_action_just_pressed("interact"):
		interact()

func interact() -> void:
	var dialogue_ui = get_tree().current_scene.get_node("DialogueUI")
	if dialogue_ui.is_open:
		return
	
	match QuestManager.quest_state:
		QuestManager.QuestState.NOT_STARTED:
			var mensajes: Array[String] = [
				"Guardian, necesito tu ayuda!",
				"Los enemigos han dispersado los 3 cristales mágicos alrededor de la ciudad",
				"Recupéralos rápido y tráemelos antes de que se pierdan"
			]
			dialogue_ui.show_dialogue(
				"Han Solo",
				mensajes
			)
			QuestManager.start_quest()
		QuestManager.QuestState.ACTIVE:
			var mensajes: Array[String] = [
				"Todavía faltan cristales.",
				"Solo encontraste %d de %d" % [
					QuestManager.collected_crystals,
					QuestManager.required_crystals
				]
			]
			dialogue_ui.show_dialogue(
				"Han Solo",
				mensajes
			)
		QuestManager.QuestState.READY_TO_DELIVER:
			var mensajes: Array[String] = [
					"Pefecto!, muchas gracias por ayudarme",
					"Has recuperado todos los cristales a tiempo.",
					"Ahora podemos activar el portal."
				]
			dialogue_ui.show_dialogue(
				"Han Solo",
				mensajes
			)
			QuestManager.complete_quest()
		QuestManager.QuestState.COMPLETED:
			var mensajes: Array[String] = [
					"Gracias por tu gran ayuda!",
					"El portal está listo para ser utilizado.",
					"Buen viaje!"
				]
			dialogue_ui.show_dialogue(
				"Han Solo",
				mensajes
			)

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_nearby = true


func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_nearby = false
