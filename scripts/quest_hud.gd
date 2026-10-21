extends CanvasLayer

@onready var quest_label: Label = $QuestLabel


func _ready() -> void:
	QuestManager.quest_updated.connect(update_quest_text)
	update_quest_text()


func update_quest_text() -> void:
	match QuestManager.quest_state:

		QuestManager.QuestState.NOT_STARTED:
			quest_label.text = "Misión: habla con el profesor"

		QuestManager.QuestState.ACTIVE:
			quest_label.text = "Cristales: %d/%d" % [
				QuestManager.collected_crystals,
				QuestManager.required_crystals
			]

		QuestManager.QuestState.READY_TO_DELIVER:
			quest_label.text = "Regresa con el profesor"

		QuestManager.QuestState.COMPLETED:
			quest_label.text = "Misión completada"
